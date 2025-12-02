//! Synapse CLI - Command-line interface for Synapse Protocol.

use clap::{Parser, Subcommand};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod commands;

#[derive(Parser)]
#[command(name = "synapse")]
#[command(author, version, about = "Synapse Protocol - Distributed AI Memory System")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    
    /// Enable verbose logging
    #[arg(short, long, global = true)]
    verbose: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize a new Synapse database
    Init {
        /// Path to store the database
        #[arg(short, long, default_value = "./synapse_data")]
        path: String,
    },
    
    /// Store a memory
    Store {
        /// Content to store
        content: String,
        
        /// Namespace (for multi-tenant)
        #[arg(short, long, default_value = "default")]
        namespace: String,
    },
    
    /// Search memories
    Search {
        /// Query text
        query: String,
        
        /// Number of results
        #[arg(short, long, default_value = "5")]
        top_k: usize,
    },
    
    /// Show statistics
    Stats,
    
    /// Chat with the AI (interactive mode)
    Chat,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();
    
    // Initialize logging
    let filter = if cli.verbose { "debug" } else { "info" };
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| filter.into()))
        .with(tracing_subscriber::fmt::layer())
        .init();
    
    match cli.command {
        Commands::Init { path } => {
            commands::init(&path).await?;
        }
        Commands::Store { content, namespace } => {
            commands::store(&content, &namespace).await?;
        }
        Commands::Search { query, top_k } => {
            commands::search(&query, top_k).await?;
        }
        Commands::Stats => {
            commands::stats().await?;
        }
        Commands::Chat => {
            commands::chat().await?;
        }
    }
    
    Ok(())
}
