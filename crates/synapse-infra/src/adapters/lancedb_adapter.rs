//! LanceDB adapter for long-term memory storage.
//!
//! This adapter implements `MemoryPort` using LanceDB as the vector database.
//! It supports vector similarity search, filtering by layer (HiRAG), and namespace (multi-tenant).

use async_trait::async_trait;
use arrow_array::{
    Array, Float32Array, Int64Array, RecordBatch, RecordBatchIterator, StringArray, UInt8Array,
    FixedSizeListArray, ArrayRef,
};
use arrow_schema::{DataType, Field, Schema};
use futures::TryStreamExt;
use lancedb::{connect, query::ExecutableQuery, query::QueryBase, Connection, Table};
use std::sync::Arc;
use synapse_core::{CoreError, MemoryNode, MemoryPort, NodeType, SearchResult};
use tokio::sync::RwLock;

use crate::InfraError;

/// Default embedding dimension (MiniLM).
const DEFAULT_EMBEDDING_DIM: usize = 384;

/// LanceDB adapter for vector storage.
///
/// This adapter provides:
/// - Vector similarity search using ANN
/// - Filtering by HiRAG layer
/// - Namespace isolation for multi-tenancy
/// - Full CRUD operations on memory nodes
pub struct LanceDbAdapter {
    conn: Connection,
    table: RwLock<Option<Table>>,
    table_name: String,
    embedding_dim: usize,
}

impl LanceDbAdapter {
    /// Create a new LanceDB adapter.
    ///
    /// # Arguments
    /// * `path` - Path to the LanceDB database directory
    /// * `table_name` - Name of the table to use
    ///
    /// # Errors
    /// Returns `InfraError::LanceDb` if connection fails
    pub async fn new(path: &str, table_name: &str) -> Result<Self, InfraError> {
        Self::with_embedding_dim(path, table_name, DEFAULT_EMBEDDING_DIM).await
    }

    /// Create a new LanceDB adapter with custom embedding dimension.
    pub async fn with_embedding_dim(
        path: &str,
        table_name: &str,
        embedding_dim: usize
    ) -> Result<Self, InfraError> {
        let conn = connect(path)
            .execute()
            .await
            .map_err(|e| InfraError::LanceDb(format!("Failed to connect: {}", e)))?;

        let adapter = Self {
            conn,
            table: RwLock::new(None),
            table_name: table_name.to_string(),
            embedding_dim,
        };

        // Try to open existing table or create new one
        adapter.ensure_table().await?;

        Ok(adapter)
    }

    /// Get the Arrow schema for the memory table.
    fn get_schema(&self) -> Schema {
        Schema::new(vec![
            Field::new("id", DataType::Utf8, false),
            Field::new("content", DataType::Utf8, false),
            Field::new("layer", DataType::UInt8, false),
            Field::new("node_type", DataType::Utf8, false),
            Field::new("created_at", DataType::Int64, false),
            Field::new("updated_at", DataType::Int64, false),
            Field::new(
                "embedding",
                DataType::FixedSizeList(
                    Arc::new(Field::new("item", DataType::Float32, true)),
                    self.embedding_dim as i32,
                ),
                false,
            ),
            Field::new("metadata", DataType::Utf8, false), // JSON string
            Field::new("namespace", DataType::Utf8, false),
            Field::new("source", DataType::Utf8, false),
        ])
    }

    /// Ensure the table exists, creating it if necessary.
    async fn ensure_table(&self) -> Result<(), InfraError> {
        let mut table_guard = self.table.write().await;

        if table_guard.is_some() {
            return Ok(());
        }

        // Try to open existing table
        match self.conn.open_table(&self.table_name).execute().await {
            Ok(table) => {
                *table_guard = Some(table);
                return Ok(());
            }
            Err(_) => {
                // Table doesn't exist, create it with empty data
                let schema = Arc::new(self.get_schema());
                let batches: Vec<RecordBatch> = vec![];
                let batch_iter = RecordBatchIterator::new(
                    batches.into_iter().map(Ok),
                    schema.clone(),
                );

                let table = self.conn
                    .create_table(&self.table_name, Box::new(batch_iter))
                    .execute()
                    .await
                    .map_err(|e| InfraError::LanceDb(format!("Failed to create table: {}", e)))?;

                *table_guard = Some(table);
            }
        }

        Ok(())
    }

    /// Get the table, ensuring it exists.
    async fn get_table(&self) -> Result<Table, InfraError> {
        self.ensure_table().await?;
        let table_guard = self.table.read().await;
        table_guard.clone().ok_or_else(|| InfraError::LanceDb("Table not initialized".to_string()))
    }

    /// Convert a MemoryNode to a RecordBatch.
    fn node_to_batch(&self, node: &MemoryNode) -> Result<RecordBatch, InfraError> {
        let schema = Arc::new(self.get_schema());

        // Validate embedding dimension
        if node.embedding.len() != self.embedding_dim {
            return Err(InfraError::LanceDb(format!(
                "Embedding dimension mismatch: expected {}, got {}",
                self.embedding_dim,
                node.embedding.len()
            )));
        }

        let id_array = StringArray::from(vec![node.id.as_str()]);
        let content_array = StringArray::from(vec![node.content.as_str()]);
        let layer_array = UInt8Array::from(vec![node.layer]);
        let node_type_array = StringArray::from(vec![node.node_type.to_string()]);
        let created_at_array = Int64Array::from(vec![node.created_at]);
        let updated_at_array = Int64Array::from(vec![node.updated_at]);

        // Create embedding array as FixedSizeList
        let embedding_values = Float32Array::from(node.embedding.clone());
        let field = Arc::new(Field::new("item", DataType::Float32, true));
        let embedding_array = FixedSizeListArray::new(
            field,
            self.embedding_dim as i32,
            Arc::new(embedding_values) as ArrayRef,
            None,
        );

        let metadata_json = serde_json::to_string(&node.metadata)
            .map_err(|e| InfraError::LanceDb(format!("Failed to serialize metadata: {}", e)))?;
        let metadata_array = StringArray::from(vec![metadata_json.as_str()]);

        let namespace_array = StringArray::from(vec![node.namespace.as_str()]);
        let source_array = StringArray::from(vec![node.source.as_str()]);

        RecordBatch::try_new(
            schema,
            vec![
                Arc::new(id_array),
                Arc::new(content_array),
                Arc::new(layer_array),
                Arc::new(node_type_array),
                Arc::new(created_at_array),
                Arc::new(updated_at_array),
                Arc::new(embedding_array),
                Arc::new(metadata_array),
                Arc::new(namespace_array),
                Arc::new(source_array),
            ],
        )
        .map_err(|e| InfraError::LanceDb(format!("Failed to create batch: {}", e)))
    }

    /// Convert a RecordBatch row to a MemoryNode.
    fn batch_to_node(&self, batch: &RecordBatch, row: usize) -> Result<MemoryNode, InfraError> {
        let id = batch
            .column_by_name("id")
            .and_then(|c| c.as_any().downcast_ref::<StringArray>())
            .map(|a| a.value(row).to_string())
            .ok_or_else(|| InfraError::LanceDb("Missing id column".to_string()))?;

        let content = batch
            .column_by_name("content")
            .and_then(|c| c.as_any().downcast_ref::<StringArray>())
            .map(|a| a.value(row).to_string())
            .ok_or_else(|| InfraError::LanceDb("Missing content column".to_string()))?;

        let layer = batch
            .column_by_name("layer")
            .and_then(|c| c.as_any().downcast_ref::<UInt8Array>())
            .map(|a| a.value(row))
            .ok_or_else(|| InfraError::LanceDb("Missing layer column".to_string()))?;

        let node_type_str = batch
            .column_by_name("node_type")
            .and_then(|c| c.as_any().downcast_ref::<StringArray>())
            .map(|a| a.value(row).to_string())
            .ok_or_else(|| InfraError::LanceDb("Missing node_type column".to_string()))?;
        let node_type = Self::parse_node_type(&node_type_str);

        let created_at = batch
            .column_by_name("created_at")
            .and_then(|c| c.as_any().downcast_ref::<Int64Array>())
            .map(|a| a.value(row))
            .ok_or_else(|| InfraError::LanceDb("Missing created_at column".to_string()))?;

        let updated_at = batch
            .column_by_name("updated_at")
            .and_then(|c| c.as_any().downcast_ref::<Int64Array>())
            .map(|a| a.value(row))
            .ok_or_else(|| InfraError::LanceDb("Missing updated_at column".to_string()))?;

        // Extract embedding from FixedSizeList
        let embedding = batch
            .column_by_name("embedding")
            .and_then(|c| c.as_any().downcast_ref::<FixedSizeListArray>())
            .and_then(|a| {
                let values = a.value(row);
                values.as_any().downcast_ref::<Float32Array>().map(|f| {
                    (0..f.len()).map(|i| f.value(i)).collect::<Vec<f32>>()
                })
            })
            .ok_or_else(|| InfraError::LanceDb("Missing embedding column".to_string()))?;

        let metadata_str = batch
            .column_by_name("metadata")
            .and_then(|c| c.as_any().downcast_ref::<StringArray>())
            .map(|a| a.value(row).to_string())
            .ok_or_else(|| InfraError::LanceDb("Missing metadata column".to_string()))?;
        let metadata = serde_json::from_str(&metadata_str)
            .unwrap_or_default();

        let namespace = batch
            .column_by_name("namespace")
            .and_then(|c| c.as_any().downcast_ref::<StringArray>())
            .map(|a| a.value(row).to_string())
            .ok_or_else(|| InfraError::LanceDb("Missing namespace column".to_string()))?;

        let source = batch
            .column_by_name("source")
            .and_then(|c| c.as_any().downcast_ref::<StringArray>())
            .map(|a| a.value(row).to_string())
            .ok_or_else(|| InfraError::LanceDb("Missing source column".to_string()))?;

        Ok(MemoryNode {
            id,
            content,
            layer,
            node_type,
            created_at,
            updated_at,
            embedding,
            metadata,
            namespace,
            source,
        })
    }

    /// Extract distance from a search result batch.
    fn get_distance(batch: &RecordBatch, row: usize) -> f32 {
        batch
            .column_by_name("_distance")
            .and_then(|c| c.as_any().downcast_ref::<Float32Array>())
            .map(|a| a.value(row))
            .unwrap_or(f32::MAX)
    }

    /// Parse NodeType from string.
    fn parse_node_type(s: &str) -> NodeType {
        match s.to_lowercase().as_str() {
            "fact" => NodeType::Fact,
            "summary" => NodeType::Summary,
            "thought" => NodeType::Thought,
            "profile" => NodeType::Profile,
            "system" => NodeType::System,
            "external" => NodeType::External,
            _ => NodeType::Fact,
        }
    }
}

#[async_trait]
impl MemoryPort for LanceDbAdapter {
    async fn store(&self, node: MemoryNode) -> Result<String, CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let batch = self.node_to_batch(&node)
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let schema = batch.schema();
        let batch_iter = RecordBatchIterator::new(
            vec![Ok(batch)].into_iter(),
            schema,
        );

        table
            .add(Box::new(batch_iter))
            .execute()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Failed to store: {}", e) })?;

        Ok(node.id.clone())
    }

    async fn search(&self, embedding: &[f32], top_k: usize) -> Result<Vec<SearchResult>, CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let batches: Vec<RecordBatch> = table
            .vector_search(embedding)
            .map_err(|e| CoreError::Internal { message: format!("Search failed: {}", e) })?
            .limit(top_k)
            .execute()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Search execute failed: {}", e) })?
            .try_collect()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Collect failed: {}", e) })?;

        let mut results = Vec::new();
        for batch in &batches {
            for row in 0..batch.num_rows() {
                let node = self.batch_to_node(batch, row)
                    .map_err(|e| CoreError::Internal { message: e.to_string() })?;
                let distance = Self::get_distance(batch, row);
                results.push(SearchResult { node, distance });
            }
        }

        Ok(results)
    }

    async fn search_layer(
        &self,
        embedding: &[f32],
        layer: u8,
        top_k: usize,
    ) -> Result<Vec<SearchResult>, CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let filter = format!("layer = {}", layer);

        let batches: Vec<RecordBatch> = table
            .vector_search(embedding)
            .map_err(|e| CoreError::Internal { message: format!("Search failed: {}", e) })?
            .only_if(filter)
            .limit(top_k)
            .execute()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Search execute failed: {}", e) })?
            .try_collect()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Collect failed: {}", e) })?;

        let mut results = Vec::new();
        for batch in &batches {
            for row in 0..batch.num_rows() {
                let node = self.batch_to_node(batch, row)
                    .map_err(|e| CoreError::Internal { message: e.to_string() })?;
                let distance = Self::get_distance(batch, row);
                results.push(SearchResult { node, distance });
            }
        }

        Ok(results)
    }

    async fn search_namespace(
        &self,
        embedding: &[f32],
        namespace: &str,
        top_k: usize,
    ) -> Result<Vec<SearchResult>, CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let filter = format!("namespace = '{}'", namespace);

        let batches: Vec<RecordBatch> = table
            .vector_search(embedding)
            .map_err(|e| CoreError::Internal { message: format!("Search failed: {}", e) })?
            .only_if(filter)
            .limit(top_k)
            .execute()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Search execute failed: {}", e) })?
            .try_collect()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Collect failed: {}", e) })?;

        let mut results = Vec::new();
        for batch in &batches {
            for row in 0..batch.num_rows() {
                let node = self.batch_to_node(batch, row)
                    .map_err(|e| CoreError::Internal { message: e.to_string() })?;
                let distance = Self::get_distance(batch, row);
                results.push(SearchResult { node, distance });
            }
        }

        Ok(results)
    }

    async fn get_by_id(&self, id: &str) -> Result<Option<MemoryNode>, CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let filter = format!("id = '{}'", id);

        let batches: Vec<RecordBatch> = table
            .query()
            .only_if(filter)
            .limit(1)
            .execute()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Query failed: {}", e) })?
            .try_collect()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Collect failed: {}", e) })?;

        if let Some(batch) = batches.first() {
            if batch.num_rows() > 0 {
                let node = self.batch_to_node(batch, 0)
                    .map_err(|e| CoreError::Internal { message: e.to_string() })?;
                return Ok(Some(node));
            }
        }

        Ok(None)
    }

    async fn get_by_layer(&self, layer: u8) -> Result<Vec<MemoryNode>, CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let filter = format!("layer = {}", layer);

        let batches: Vec<RecordBatch> = table
            .query()
            .only_if(filter)
            .execute()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Query failed: {}", e) })?
            .try_collect()
            .await
            .map_err(|e| CoreError::Internal { message: format!("Collect failed: {}", e) })?;

        let mut nodes = Vec::new();
        for batch in &batches {
            for row in 0..batch.num_rows() {
                let node = self.batch_to_node(batch, row)
                    .map_err(|e| CoreError::Internal { message: e.to_string() })?;
                nodes.push(node);
            }
        }

        Ok(nodes)
    }

    async fn update(&self, node: MemoryNode) -> Result<(), CoreError> {
        // LanceDB doesn't have direct update, so we delete and re-insert
        self.delete(&node.id).await?;
        self.store(node).await?;
        Ok(())
    }

    async fn delete(&self, id: &str) -> Result<(), CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let predicate = format!("id = '{}'", id);

        table
            .delete(&predicate)
            .await
            .map_err(|e| CoreError::Internal { message: format!("Delete failed: {}", e) })?;

        Ok(())
    }

    async fn count(&self) -> Result<usize, CoreError> {
        let table = self.get_table().await
            .map_err(|e| CoreError::Internal { message: e.to_string() })?;

        let count = table
            .count_rows(None)
            .await
            .map_err(|e| CoreError::Internal { message: format!("Count failed: {}", e) })?;

        Ok(count)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    fn create_test_node(id: &str, content: &str) -> MemoryNode {
        MemoryNode {
            id: id.to_string(),
            content: content.to_string(),
            layer: 0,
            node_type: NodeType::Fact,
            created_at: 1000,
            updated_at: 1000,
            embedding: vec![0.1; DEFAULT_EMBEDDING_DIM],
            metadata: Default::default(),
            namespace: "default".to_string(),
            source: "test".to_string(),
        }
    }

    #[tokio::test]
    async fn test_adapter_creation() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "test_table").await;
        assert!(adapter.is_ok());
    }

    #[tokio::test]
    async fn test_store_and_get_by_id() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();
        let node = create_test_node("test-1", "Test memory content");

        // Store
        let id = adapter.store(node.clone()).await.unwrap();
        assert_eq!(id, "test-1");

        // Retrieve
        let retrieved = adapter.get_by_id("test-1").await.unwrap();
        assert!(retrieved.is_some());
        let retrieved = retrieved.unwrap();
        assert_eq!(retrieved.id, "test-1");
        assert_eq!(retrieved.content, "Test memory content");
    }

    #[tokio::test]
    async fn test_search() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Store multiple nodes
        let node1 = create_test_node("search-1", "First memory");
        let node2 = create_test_node("search-2", "Second memory");

        adapter.store(node1.clone()).await.unwrap();
        adapter.store(node2.clone()).await.unwrap();

        // Search
        let results = adapter.search(&node1.embedding, 5).await.unwrap();
        assert!(!results.is_empty());
        assert!(results.len() <= 5);
    }

    #[tokio::test]
    async fn test_search_layer() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Store nodes in different layers
        let mut node0 = create_test_node("layer-0", "Base fact");
        node0.layer = 0;

        let mut node1 = create_test_node("layer-1", "Summary");
        node1.layer = 1;

        adapter.store(node0.clone()).await.unwrap();
        adapter.store(node1.clone()).await.unwrap();

        // Search layer 0 only
        let results = adapter.search_layer(&node0.embedding, 0, 5).await.unwrap();
        assert!(!results.is_empty());
        for result in &results {
            assert_eq!(result.node.layer, 0);
        }
    }

    #[tokio::test]
    async fn test_search_namespace() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Store nodes in different namespaces
        let mut node_a = create_test_node("ns-a", "Namespace A memory");
        node_a.namespace = "tenant-a".to_string();

        let mut node_b = create_test_node("ns-b", "Namespace B memory");
        node_b.namespace = "tenant-b".to_string();

        adapter.store(node_a.clone()).await.unwrap();
        adapter.store(node_b.clone()).await.unwrap();

        // Search tenant-a namespace only
        let results = adapter.search_namespace(&node_a.embedding, "tenant-a", 5).await.unwrap();
        assert!(!results.is_empty());
        for result in &results {
            assert_eq!(result.node.namespace, "tenant-a");
        }
    }

    #[tokio::test]
    async fn test_get_by_layer() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Store nodes in different layers
        let mut node0a = create_test_node("layer0-a", "Fact A");
        node0a.layer = 0;

        let mut node0b = create_test_node("layer0-b", "Fact B");
        node0b.layer = 0;

        let mut node1 = create_test_node("layer1", "Summary");
        node1.layer = 1;

        adapter.store(node0a).await.unwrap();
        adapter.store(node0b).await.unwrap();
        adapter.store(node1).await.unwrap();

        // Get all layer 0 nodes
        let layer0_nodes = adapter.get_by_layer(0).await.unwrap();
        assert_eq!(layer0_nodes.len(), 2);

        // Get all layer 1 nodes
        let layer1_nodes = adapter.get_by_layer(1).await.unwrap();
        assert_eq!(layer1_nodes.len(), 1);
    }

    #[tokio::test]
    async fn test_update() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Store
        let node = create_test_node("update-test", "Original content");
        adapter.store(node.clone()).await.unwrap();

        // Update
        let mut updated_node = node.clone();
        updated_node.content = "Updated content".to_string();
        updated_node.updated_at = 2000;
        adapter.update(updated_node).await.unwrap();

        // Verify
        let retrieved = adapter.get_by_id("update-test").await.unwrap().unwrap();
        assert_eq!(retrieved.content, "Updated content");
        assert_eq!(retrieved.updated_at, 2000);
    }

    #[tokio::test]
    async fn test_delete() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Store
        let node = create_test_node("delete-test", "To be deleted");
        adapter.store(node).await.unwrap();

        // Verify exists
        let exists = adapter.get_by_id("delete-test").await.unwrap();
        assert!(exists.is_some());

        // Delete
        adapter.delete("delete-test").await.unwrap();

        // Verify deleted
        let deleted = adapter.get_by_id("delete-test").await.unwrap();
        assert!(deleted.is_none());
    }

    #[tokio::test]
    async fn test_count() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Initially empty
        let count = adapter.count().await.unwrap();
        assert_eq!(count, 0);

        // Add nodes
        adapter.store(create_test_node("count-1", "First")).await.unwrap();
        adapter.store(create_test_node("count-2", "Second")).await.unwrap();
        adapter.store(create_test_node("count-3", "Third")).await.unwrap();

        // Verify count
        let count = adapter.count().await.unwrap();
        assert_eq!(count, 3);
    }

    #[tokio::test]
    async fn test_embedding_dimension_validation() {
        let temp_dir = TempDir::new().unwrap();
        let path = temp_dir.path().to_str().unwrap();

        let adapter = LanceDbAdapter::new(path, "memories").await.unwrap();

        // Try to store with wrong embedding dimension
        let mut node = create_test_node("wrong-dim", "Wrong dimension");
        node.embedding = vec![0.1; 100]; // Wrong dimension (should be 384)

        let result = adapter.store(node).await;
        assert!(result.is_err());
    }
}

