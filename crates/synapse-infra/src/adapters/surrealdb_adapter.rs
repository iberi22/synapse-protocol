//! SurrealDB adapter for long-term memory storage.
//!
//! Implements the MemoryPort trait using SurrealDB's embedded mode
//! with vector search, graph relations, and namespace support.

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use surrealdb::engine::local::{Db, Mem, SurrealKv};
use surrealdb::sql::Thing;
use surrealdb::Surreal;
use synapse_core::{error::Error, MemoryNode, MemoryPort, NodeType, SearchResult};
use std::sync::Arc;
use tokio::sync::OnceCell;

/// Record type for SurrealDB serialization.
#[derive(Debug, Serialize, Deserialize)]
struct MemoryRecord {
    content: String,
    layer: u8,
    node_type: String,
    created_at: i64,
    updated_at: i64,
    embedding: Vec<f32>,
    metadata: String, // JSON serialized
    namespace: String,
    source: String,
}

/// Search result from SurrealDB vector query.
#[derive(Debug, Deserialize)]
struct VectorSearchResult {
    id: Thing,
    content: String,
    layer: u8,
    node_type: String,
    created_at: i64,
    updated_at: i64,
    embedding: Vec<f32>,
    metadata: String,
    namespace: String,
    source: String,
    distance: f32,
}

/// SurrealDB adapter for vector storage with graph support.
pub struct SurrealDbAdapter {
    db: Arc<Surreal<Db>>,
    initialized: OnceCell<()>,
}

impl SurrealDbAdapter {
    /// Create a new SurrealDB adapter with file-based persistent storage.
    ///
    /// # Arguments
    /// * `path` - Path to the database directory (uses SurrealKV backend)
    ///
    /// This uses the SurrealKV embedded storage engine for persistence.
    pub async fn new(path: &str) -> Result<Self, Error> {
        // Create directory if it doesn't exist
        std::fs::create_dir_all(path)
            .map_err(|e| Error::System(format!("Failed to create DB directory: {}", e)))?;

        let db = Surreal::new::<SurrealKv>(path)
            .await
            .map_err(|e| Error::System(format!("Failed to create persistent DB: {}", e)))?;

        let adapter = Self {
            db: Arc::new(db),
            initialized: OnceCell::new(),
        };

        adapter.initialize().await?;
        Ok(adapter)
    }

    /// Create a new in-memory SurrealDB adapter (for testing and development).
    pub async fn new_memory() -> Result<Self, Error> {
        let db = Surreal::new::<Mem>(())
            .await
            .map_err(|e| Error::System(format!("Failed to create in-memory DB: {}", e)))?;

        let adapter = Self {
            db: Arc::new(db),
            initialized: OnceCell::new(),
        };

        adapter.initialize().await?;
        Ok(adapter)
    }

    /// Initialize namespace, database, and schema.
    async fn initialize(&self) -> Result<(), Error> {
        self.initialized
            .get_or_try_init(|| async {
                // Use namespace and database
                self.db
                    .use_ns("synapse")
                    .use_db("memory")
                    .await
                    .map_err(|e| Error::System(format!("Failed to select namespace: {}", e)))?;

                // Define table and indexes (idempotent)
                self.db
                    .query(
                        r#"
                        DEFINE TABLE IF NOT EXISTS memory_node SCHEMAFULL;

                        DEFINE FIELD IF NOT EXISTS content ON memory_node TYPE string;
                        DEFINE FIELD IF NOT EXISTS layer ON memory_node TYPE int;
                        DEFINE FIELD IF NOT EXISTS node_type ON memory_node TYPE string;
                        DEFINE FIELD IF NOT EXISTS created_at ON memory_node TYPE int;
                        DEFINE FIELD IF NOT EXISTS updated_at ON memory_node TYPE int;
                        DEFINE FIELD IF NOT EXISTS embedding ON memory_node TYPE array<float>;
                        DEFINE FIELD IF NOT EXISTS metadata ON memory_node TYPE string;
                        DEFINE FIELD IF NOT EXISTS namespace ON memory_node TYPE string;
                        DEFINE FIELD IF NOT EXISTS source ON memory_node TYPE string;

                        DEFINE INDEX IF NOT EXISTS idx_layer ON memory_node FIELDS layer;
                        DEFINE INDEX IF NOT EXISTS idx_namespace ON memory_node FIELDS namespace;

                        DEFINE TABLE IF NOT EXISTS summarizes SCHEMALESS;
                        "#,
                    )
                    .await
                    .map_err(|e| Error::System(format!("Failed to create schema: {}", e)))?;

                Ok::<(), Error>(())
            })
            .await?;

        Ok(())
    }

    /// Convert MemoryNode to MemoryRecord for storage.
    fn node_to_record(node: &MemoryNode) -> MemoryRecord {
        MemoryRecord {
            content: node.content.clone(),
            layer: node.layer,
            node_type: format!("{:?}", node.node_type),
            created_at: node.created_at,
            updated_at: node.updated_at,
            embedding: node.embedding.clone(),
            metadata: serde_json::to_string(&node.metadata).unwrap_or_default(),
            namespace: node.namespace.clone(),
            source: node.source.clone(),
        }
    }

    /// Convert stored record back to MemoryNode.
    fn record_to_node(id: String, record: &MemoryRecord) -> MemoryNode {
        let node_type = match record.node_type.as_str() {
            "Fact" => NodeType::Fact,
            "Summary" => NodeType::Summary,
            "Thought" => NodeType::Thought,
            "System" => NodeType::System,
            _ => NodeType::Fact,
        };

        MemoryNode {
            id,
            content: record.content.clone(),
            layer: record.layer,
            node_type,
            created_at: record.created_at,
            updated_at: record.updated_at,
            embedding: record.embedding.clone(),
            metadata: serde_json::from_str(&record.metadata).unwrap_or_default(),
            namespace: record.namespace.clone(),
            source: record.source.clone(),
        }
    }
}

#[async_trait]
impl MemoryPort for SurrealDbAdapter {
    async fn store(&self, node: MemoryNode) -> Result<String, Error> {
        let record = Self::node_to_record(&node);

        let result: Option<MemoryRecord> = self
            .db
            .create(("memory_node", node.id.clone()))
            .content(record)
            .await
            .map_err(|e| Error::System(format!("Failed to store node: {}", e)))?;

        if result.is_some() {
            Ok(node.id)
        } else {
            Err(Error::System("Failed to create record".to_string()))
        }
    }

    async fn search(&self, embedding: &[f32], top_k: usize) -> Result<Vec<SearchResult>, Error> {
        // Use cosine similarity via vector::similarity::cosine
        // SurrealDB's vector search approach
        let query = format!(
            r#"
            SELECT *,
                   vector::distance::euclidean(embedding, $embedding) AS distance
            FROM memory_node
            ORDER BY distance ASC
            LIMIT {}
            "#,
            top_k
        );

        let mut response = self
            .db
            .query(&query)
            .bind(("embedding", embedding.to_vec()))
            .await
            .map_err(|e| Error::System(format!("Search failed: {}", e)))?;

        let results: Vec<VectorSearchResult> = response
            .take(0)
            .map_err(|e| Error::System(format!("Failed to parse results: {}", e)))?;

        Ok(results
            .into_iter()
            .map(|r| {
                let id = r.id.id.to_string();
                SearchResult {
                    node: MemoryNode {
                        id: id.clone(),
                        content: r.content,
                        layer: r.layer,
                        node_type: match r.node_type.as_str() {
                            "Fact" => NodeType::Fact,
                            "Summary" => NodeType::Summary,
                            "Thought" => NodeType::Thought,
                            "System" => NodeType::System,
                            _ => NodeType::Fact,
                        },
                        created_at: r.created_at,
                        updated_at: r.updated_at,
                        embedding: r.embedding,
                        metadata: serde_json::from_str(&r.metadata).unwrap_or_default(),
                        namespace: r.namespace,
                        source: r.source,
                    },
                    distance: r.distance,
                }
            })
            .collect())
    }

    async fn search_layer(
        &self,
        embedding: &[f32],
        layer: u8,
        top_k: usize,
    ) -> Result<Vec<SearchResult>, Error> {
        let query = format!(
            r#"
            SELECT *,
                   vector::distance::euclidean(embedding, $embedding) AS distance
            FROM memory_node
            WHERE layer = $layer
            ORDER BY distance ASC
            LIMIT {}
            "#,
            top_k
        );

        let mut response = self
            .db
            .query(&query)
            .bind(("embedding", embedding.to_vec()))
            .bind(("layer", layer as i64))
            .await
            .map_err(|e| Error::System(format!("Search layer failed: {}", e)))?;

        let results: Vec<VectorSearchResult> = response
            .take(0)
            .map_err(|e| Error::System(format!("Failed to parse results: {}", e)))?;

        Ok(results
            .into_iter()
            .map(|r| {
                let id = r.id.id.to_string();
                SearchResult {
                    node: MemoryNode {
                        id: id.clone(),
                        content: r.content,
                        layer: r.layer,
                        node_type: match r.node_type.as_str() {
                            "Fact" => NodeType::Fact,
                            "Summary" => NodeType::Summary,
                            _ => NodeType::Fact,
                        },
                        created_at: r.created_at,
                        updated_at: r.updated_at,
                        embedding: r.embedding,
                        metadata: serde_json::from_str(&r.metadata).unwrap_or_default(),
                        namespace: r.namespace,
                        source: r.source,
                    },
                    distance: r.distance,
                }
            })
            .collect())
    }

    async fn search_namespace(
        &self,
        embedding: &[f32],
        namespace: &str,
        top_k: usize,
    ) -> Result<Vec<SearchResult>, Error> {
        let query = format!(
            r#"
            SELECT *,
                   vector::distance::euclidean(embedding, $embedding) AS distance
            FROM memory_node
            WHERE namespace = $namespace
            ORDER BY distance ASC
            LIMIT {}
            "#,
            top_k
        );

        let mut response = self
            .db
            .query(&query)
            .bind(("embedding", embedding.to_vec()))
            .bind(("namespace", namespace.to_string()))
            .await
            .map_err(|e| Error::System(format!("Search namespace failed: {}", e)))?;

        let results: Vec<VectorSearchResult> = response
            .take(0)
            .map_err(|e| Error::System(format!("Failed to parse results: {}", e)))?;

        Ok(results
            .into_iter()
            .map(|r| {
                let id = r.id.id.to_string();
                SearchResult {
                    node: MemoryNode {
                        id: id.clone(),
                        content: r.content,
                        layer: r.layer,
                        node_type: match r.node_type.as_str() {
                            "Fact" => NodeType::Fact,
                            "Summary" => NodeType::Summary,
                            _ => NodeType::Fact,
                        },
                        created_at: r.created_at,
                        updated_at: r.updated_at,
                        embedding: r.embedding,
                        metadata: serde_json::from_str(&r.metadata).unwrap_or_default(),
                        namespace: r.namespace,
                        source: r.source,
                    },
                    distance: r.distance,
                }
            })
            .collect())
    }

    async fn get_by_id(&self, id: &str) -> Result<Option<MemoryNode>, Error> {
        let result: Option<MemoryRecord> = self
            .db
            .select(("memory_node", id))
            .await
            .map_err(|e| Error::System(format!("Get by ID failed: {}", e)))?;

        Ok(result.map(|r| Self::record_to_node(id.to_string(), &r)))
    }

    async fn get_by_layer(&self, layer: u8) -> Result<Vec<MemoryNode>, Error> {
        let mut response = self
            .db
            .query("SELECT * FROM memory_node WHERE layer = $layer")
            .bind(("layer", layer as i64))
            .await
            .map_err(|e| Error::System(format!("Get by layer failed: {}", e)))?;

        #[derive(Deserialize)]
        struct LayerResult {
            id: Thing,
            content: String,
            layer: u8,
            node_type: String,
            created_at: i64,
            updated_at: i64,
            embedding: Vec<f32>,
            metadata: String,
            namespace: String,
            source: String,
        }

        let results: Vec<LayerResult> = response
            .take(0)
            .map_err(|e| Error::System(format!("Failed to parse layer results: {}", e)))?;

        Ok(results
            .into_iter()
            .map(|r| MemoryNode {
                id: r.id.id.to_string(),
                content: r.content,
                layer: r.layer,
                node_type: match r.node_type.as_str() {
                    "Fact" => NodeType::Fact,
                    "Summary" => NodeType::Summary,
                    "Thought" => NodeType::Thought,
                    "System" => NodeType::System,
                    _ => NodeType::Fact,
                },
                created_at: r.created_at,
                updated_at: r.updated_at,
                embedding: r.embedding,
                metadata: serde_json::from_str(&r.metadata).unwrap_or_default(),
                namespace: r.namespace,
                source: r.source,
            })
            .collect())
    }

    async fn update(&self, node: MemoryNode) -> Result<(), Error> {
        let record = Self::node_to_record(&node);

        let _: Option<MemoryRecord> = self
            .db
            .update(("memory_node", node.id.clone()))
            .content(record)
            .await
            .map_err(|e| Error::System(format!("Update failed: {}", e)))?;

        Ok(())
    }

    async fn delete(&self, id: &str) -> Result<(), Error> {
        let _: Option<MemoryRecord> = self
            .db
            .delete(("memory_node", id))
            .await
            .map_err(|e| Error::System(format!("Delete failed: {}", e)))?;

        Ok(())
    }

    async fn count(&self) -> Result<usize, Error> {
        let mut response = self
            .db
            .query("SELECT count() FROM memory_node GROUP ALL")
            .await
            .map_err(|e| Error::System(format!("Count failed: {}", e)))?;

        #[derive(Deserialize)]
        struct CountResult {
            count: usize,
        }

        let result: Option<CountResult> = response
            .take(0)
            .map_err(|e| Error::System(format!("Failed to parse count: {}", e)))?;

        Ok(result.map(|r| r.count).unwrap_or(0))
    }

    async fn add_relationship(&self, from_id: &str, relation: &str, to_id: &str) -> Result<(), Error> {
        // Use backtick-escaped record IDs for UUIDs with hyphens
        // SurrealDB syntax: RELATE memory_node:`uuid`->relation->memory_node:`uuid`
        let query = format!(
            "RELATE memory_node:`{}`->{}->memory_node:`{}`",
            from_id, relation, to_id
        );

        self.db
            .query(&query)
            .await
            .map_err(|e| Error::System(format!("Failed to create relationship: {}", e)))?;

        Ok(())
    }

    async fn count_by_layer(&self, layer: u8) -> Result<usize, Error> {
        let mut response = self
            .db
            .query("SELECT count() FROM memory_node WHERE layer = $layer GROUP ALL")
            .bind(("layer", layer as i64))
            .await
            .map_err(|e| Error::System(format!("Count by layer failed: {}", e)))?;

        #[derive(Deserialize)]
        struct CountResult {
            count: usize,
        }

        let result: Option<CountResult> = response
            .take(0)
            .map_err(|e| Error::System(format!("Failed to parse layer count: {}", e)))?;

        Ok(result.map(|r| r.count).unwrap_or(0))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_create_in_memory() {
        let adapter = SurrealDbAdapter::new_memory().await;
        assert!(adapter.is_ok());
    }

    #[tokio::test]
    async fn test_store_and_retrieve() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        let node = MemoryNode::new("Test content".to_string())
            .with_embedding(vec![0.1, 0.2, 0.3]);

        let id = adapter.store(node.clone()).await.unwrap();
        assert!(!id.is_empty());

        let retrieved = adapter.get_by_id(&id).await.unwrap();
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().content, "Test content");
    }

    #[tokio::test]
    async fn test_count() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        let initial_count = adapter.count().await.unwrap();
        assert_eq!(initial_count, 0);

        let node = MemoryNode::new("Test".to_string())
            .with_embedding(vec![0.1, 0.2, 0.3]);
        adapter.store(node).await.unwrap();

        let count = adapter.count().await.unwrap();
        assert_eq!(count, 1);
    }

    #[tokio::test]
    async fn test_delete() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        let node = MemoryNode::new("To delete".to_string())
            .with_embedding(vec![0.1, 0.2, 0.3]);
        let id = node.id.clone();
        adapter.store(node).await.unwrap();

        adapter.delete(&id).await.unwrap();

        let retrieved = adapter.get_by_id(&id).await.unwrap();
        assert!(retrieved.is_none());
    }

    #[tokio::test]
    async fn test_vector_search() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        // Store nodes with different embeddings
        let node1 = MemoryNode::new("Close vector".to_string())
            .with_embedding(vec![0.1, 0.2, 0.3]);
        let node2 = MemoryNode::new("Far vector".to_string())
            .with_embedding(vec![0.9, 0.8, 0.7]);

        adapter.store(node1).await.unwrap();
        adapter.store(node2).await.unwrap();

        // Search for vectors close to [0.1, 0.2, 0.3]
        let query = vec![0.1, 0.2, 0.3];
        let results = adapter.search(&query, 2).await.unwrap();

        assert_eq!(results.len(), 2);
        // First result should be closer
        assert!(results[0].distance < results[1].distance);
    }

    #[tokio::test]
    async fn test_search_by_layer() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        let fact = MemoryNode::with_layer("Layer 0 fact".to_string(), 0)
            .with_embedding(vec![0.1, 0.2, 0.3]);
        let summary = MemoryNode::with_layer("Layer 1 summary".to_string(), 1)
            .with_embedding(vec![0.1, 0.2, 0.3]);

        adapter.store(fact).await.unwrap();
        adapter.store(summary).await.unwrap();

        // Search only layer 0
        let results = adapter.search_layer(&[0.1, 0.2, 0.3], 0, 10).await.unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].node.layer, 0);
    }

    #[tokio::test]
    async fn test_search_by_namespace() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        let personal = MemoryNode::new("Personal data".to_string())
            .with_namespace("personal".to_string())
            .with_embedding(vec![0.1, 0.2, 0.3]);
        let medical = MemoryNode::new("Medical data".to_string())
            .with_namespace("orionhealth".to_string())
            .with_embedding(vec![0.1, 0.2, 0.3]);

        adapter.store(personal).await.unwrap();
        adapter.store(medical).await.unwrap();

        // Search only personal namespace
        let results = adapter
            .search_namespace(&[0.1, 0.2, 0.3], "personal", 10)
            .await
            .unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].node.namespace, "personal");
    }

    #[tokio::test]
    async fn test_hirag_relationships() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        let fact = MemoryNode::new("Fact node".to_string());
        let summary = MemoryNode::new("Summary node".to_string());

        let fact_id = adapter.store(fact).await.unwrap();
        let summary_id = adapter.store(summary).await.unwrap();

        // Create relationship: Summary -> summarizes -> Fact
        adapter
            .add_relationship(&summary_id, "summarizes", &fact_id)
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn test_count_by_layer() {
        let adapter = SurrealDbAdapter::new_memory().await.unwrap();

        // Initially no nodes
        assert_eq!(adapter.count_by_layer(0).await.unwrap(), 0);
        assert_eq!(adapter.count_by_layer(1).await.unwrap(), 0);

        // Add Layer 0 nodes
        let fact1 = MemoryNode::with_layer("Fact 1".to_string(), 0)
            .with_embedding(vec![0.1, 0.2, 0.3]);
        let fact2 = MemoryNode::with_layer("Fact 2".to_string(), 0)
            .with_embedding(vec![0.1, 0.2, 0.3]);
        adapter.store(fact1).await.unwrap();
        adapter.store(fact2).await.unwrap();

        // Add Layer 1 node
        let summary = MemoryNode::with_layer("Summary".to_string(), 1)
            .with_embedding(vec![0.1, 0.2, 0.3]);
        adapter.store(summary).await.unwrap();

        // Verify counts
        assert_eq!(adapter.count_by_layer(0).await.unwrap(), 2);
        assert_eq!(adapter.count_by_layer(1).await.unwrap(), 1);
        assert_eq!(adapter.count_by_layer(2).await.unwrap(), 0);
    }
}
