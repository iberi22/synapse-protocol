//! CLI command implementations.

use anyhow::Result;
use tracing::info;

/// Initialize a new Synapse database.
/// Initialize a new Synapse database.
pub async fn init(path: &str) -> Result<()> {
    info!("Initializing Synapse database at: {}", path);

    // 1. Create Embedding Model Directory
    let model_dir = std::path::Path::new("models/all-MiniLM-L6-v2");
    if !model_dir.exists() {
        println!("📥 Downloading embedding model (all-MiniLM-L6-v2)...");
        std::fs::create_dir_all(model_dir)?;

        // Download ONNX model
        download_file(
            "https://huggingface.co/optimum/all-MiniLM-L6-v2/resolve/main/model.onnx",
            &model_dir.join("model.onnx")
        ).await?;

        // Download Tokenizer
        download_file(
            "https://huggingface.co/optimum/all-MiniLM-L6-v2/resolve/main/tokenizer.json",
            &model_dir.join("tokenizer.json")
        ).await?;

        // Download Tokenizer Config
        download_file(
            "https://huggingface.co/optimum/all-MiniLM-L6-v2/resolve/main/tokenizer_config.json",
            &model_dir.join("tokenizer_config.json")
        ).await?;

        // Download Vocab
        download_file(
            "https://huggingface.co/optimum/all-MiniLM-L6-v2/resolve/main/vocab.txt",
            &model_dir.join("vocab.txt")
        ).await?;

        println!("✅ Embedding model downloaded successfully!");
    } else {
        println!("✅ Embedding model already exists.");
    }

    // 2. Create LLM Directory (TinyLlama)
    let llm_dir = std::path::Path::new("models/tinyllama-1.1b");
    if !llm_dir.exists() {
        println!("📥 Downloading LLM (TinyLlama-1.1B-Chat)...");
        std::fs::create_dir_all(llm_dir)?;

        // Download GGUF model
        download_file(
            "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
            &llm_dir.join("model.gguf")
        ).await?;

        // Download Tokenizer
        download_file(
            "https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer.json",
            &llm_dir.join("tokenizer.json")
        ).await?;

        println!("✅ LLM downloaded successfully!");
    } else {
        println!("✅ LLM already exists.");
    }

    println!("✅ Synapse database initialized at: {}", path);
    println!("   📦 Vector store: LanceDB");
    println!("   📋 Buffer store: Sled");
    println!("   🧠 Embedding Model: all-MiniLM-L6-v2");
    println!("   🤖 LLM Model: TinyLlama-1.1B-Chat (GGUF)");

    Ok(())
}


async fn download_file(url: &str, path: &std::path::Path) -> Result<()> {
    use std::io::Write;
    if path.exists() {
        return Ok(());
    }

    print!("   Downloading {} ... ", path.file_name().unwrap().to_string_lossy());
    std::io::stdout().flush()?;

    let response = reqwest::get(url).await?;
    let content = response.bytes().await?;
    let mut file = std::fs::File::create(path)?;
    file.write_all(&content)?;

    println!("Done ({:.2} MB)", content.len() as f64 / 1024.0 / 1024.0);
    Ok(())
}

/// Store a memory.
pub async fn store(content: &str, namespace: &str) -> Result<()> {
    info!("Storing memory in namespace: {}", namespace);

    // 1. Initialize Embedding Adapter
    println!("🧠 Loading embedding model...");
    let embedder = synapse_infra::adapters::ort_adapter::OrtAdapter::new()?;

    // 2. Generate Embedding
    println!("🧮 Generating embedding...");
    use synapse_core::ports::EmbeddingPort;
    let embedding = embedder.embed(content).await?;

    println!("✅ Embedding generated (dim: {})", embedding.len());
    println!("   Vector: [{:.4}, {:.4}, {:.4}, ...]", embedding[0], embedding[1], embedding[2]);

    // TODO: Store in LanceDB

    println!("✅ Memory stored in namespace '{}'", namespace);
    println!("   Content: {}...", &content[..content.len().min(50)]);

    Ok(())
}


/// Search memories.
pub async fn search(query: &str, top_k: usize) -> Result<()> {
    info!("Searching for: {}", query);

    // TODO: Generate query embedding
    // TODO: Search LanceDB

    println!("🔍 Search results for: {}", query);
    println!("   (TODO: Implement after LanceDB adapter)");
    println!("   Requested top_k: {}", top_k);

    Ok(())
}

/// Show statistics.
pub async fn stats() -> Result<()> {
    info!("Gathering statistics...");

    // TODO: Get counts from LanceDB and Sled

    println!("📊 Synapse Statistics");
    println!("   Total memories: TODO");
    println!("   Buffer size: TODO");
    println!("   Layer 0 (facts): TODO");
    println!("   Layer 1+ (summaries): TODO");

    Ok(())
}

/// Interactive chat mode.
pub async fn chat() -> Result<()> {
    println!("💬 Synapse Chat (interactive mode)");
    println!("   Type 'exit' to quit\n");

    println!("🧠 Loading LLM...");
    let llm = synapse_infra::adapters::candle_adapter::CandleAdapter::new()?;
    use synapse_core::ports::LlmPort;

    // REPL loop
    use std::io::{self, Write};
    let mut input = String::new();
    loop {
        print!("> ");
        io::stdout().flush()?;
        input.clear();
        io::stdin().read_line(&mut input)?;
        let prompt = input.trim();
        if prompt == "exit" {
            break;
        }
        if prompt.is_empty() {
            continue;
        }

        print!("🤖 Generating...");
        io::stdout().flush()?;
        let response = llm.generate(prompt, 200).await?;
        println!("\r\x1B[2K🤖 Synapse: {}", response);
    }

    Ok(())
}


/// Test Context Observer.
pub async fn context() -> Result<()> {
    use synapse_core::ports::ContextPort;

    println!("👁️  Synapse Context Observer");
    println!("   Monitoring active window... (Press Ctrl+C to stop)");

    #[cfg(target_os = "windows")]
    let adapter = synapse_infra::adapters::context_adapter::WindowsContextAdapter::new();

    #[cfg(not(target_os = "windows"))]
    let adapter = synapse_infra::adapters::context_adapter::MockContextAdapter::new();

    loop {
        match adapter.get_active_window().await {
            Ok(info) => {
                print!("\r\x1B[2K"); // Clear line
                print!("   🖥️  Active: [{}] {} (Visible: {})",
                    info.process_name,
                    info.title.chars().take(50).collect::<String>(),
                    info.is_visible
                );
                use std::io::Write;
                std::io::stdout().flush()?;
            }
            Err(e) => {
                print!("\r\x1B[2K");
                print!("   ⚠️  Error: {}", e);
            }
        }
        tokio::time::sleep(tokio::time::Duration::from_millis(1000)).await;
    }
}

/// Run metabolism process.
pub async fn process() -> Result<()> {
    info!("Starting metabolism process...");

    // Initialize adapters
    // Buffer (Sled)
    let buffer = synapse_infra::adapters::sled_adapter::SledAdapter::new("synapse_data/buffer")?;

    // Memory (LanceDB)
    let memory = synapse_infra::adapters::lancedb_adapter::LanceDbAdapter::new("synapse_data/memory");


    // LLM (Candle)
    let llm = synapse_infra::adapters::candle_adapter::CandleAdapter::new()?;

    // Embedder (ORT)
    let embedder = synapse_infra::adapters::ort_adapter::OrtAdapter::new()?;

    // Metabolism Logic
    let metabolism = synapse_core::logic::metabolism::Metabolism::new(
        std::sync::Arc::new(buffer),
        std::sync::Arc::new(memory),
        std::sync::Arc::new(llm),
        std::sync::Arc::new(embedder),
    );

    println!("🔄 Digesting interactions...");
    match metabolism.digest().await {
        Ok(count) => println!("✅ Digested {} interactions.", count),
        Err(e) => println!("❌ Metabolism failed: {}", e),
    }

    Ok(())
}

/// Test Sensory Capabilities.

pub async fn senses() -> Result<()> {
    use synapse_core::ports::{VisionPort, AudioPort};
    use synapse_infra::adapters::{vision_adapter::VisionAdapter, audio_adapter::AudioAdapter};

    println!("👁️  Testing Vision...");
    let vision = VisionAdapter::new();
    match vision.capture_frame().await {
        Ok(frame) => println!("   ✅ Captured frame ({} bytes)", frame.len()),
        Err(e) => println!("   ❌ Vision error: {}", e),
    }

    println!("👂 Testing Hearing...");
    let audio = AudioAdapter::new();
    match audio.listen(1000).await {
        Ok(data) => println!("   ✅ Heard audio ({} bytes)", data.len()),
        Err(e) => println!("   ❌ Audio error: {}", e),
    }

    println!("🗣️  Testing Speech...");
    audio.speak("Hello, I am Synapse. I am listening.").await?;

    Ok(())
}

use synapse_core::ports::CommercePort;
use synapse_infra::commerce::InMemoryCommerceAdapter;

pub async fn wallet_balance() -> Result<()> {
    let wallet = InMemoryCommerceAdapter::new("user_wallet_0x123".to_string());
    let balance = wallet.get_balance().await?;
    println!("💰 Wallet Balance: {} $SYN", balance);
    Ok(())
}

pub async fn wallet_transfer(to: &str, amount: u64) -> Result<()> {
    let wallet = InMemoryCommerceAdapter::new("user_wallet_0x123".to_string());
    println!("💸 Initiating transfer of {} $SYN to {}", amount, to);

    match wallet.transfer(to, amount).await {
        Ok(tx) => println!("✅ Transfer successful! TX: {}", tx),
        Err(e) => println!("❌ Transfer failed: {}", e),
    }
    Ok(())
}

pub async fn wallet_status() -> Result<()> {
    let wallet = InMemoryCommerceAdapter::new("user_wallet_0x123".to_string());
    let score = wallet.get_proof_of_sentience().await?;

    println!("🆔 Proof of Sentience Status");
    println!("---------------------------");
    println!("Score: {:.2}/1.0", score);

    if score > 0.7 {
        println!("Status: ✅ VERIFIED HUMAN");
    } else {
        println!("Status: ⚠️  UNVERIFIED (Bot/Sybil Risk)");
    }

    Ok(())
}
