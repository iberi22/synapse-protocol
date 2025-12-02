# StatusHUD Component - System Metrics Display

## Overview
Real-time system metrics overlay showing AI "brain" activity, memory usage, and network status.

## Features (To Implement)
- [ ] Memory buffer fill percentage
- [ ] Active LoRA adapter display
- [ ] P2P sync status
- [ ] Token/s throughput meter
- [ ] Ethics check indicator (GenesisBlock)
- [ ] Minimal, non-intrusive overlay

## Implementation Guide for Jules

### Component Structure
```svelte
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { invoke } from '@tauri-apps/api/tauri';
  
  interface SystemMetrics {
    bufferFillPercent: number;
    activeAdapter: string;
    syncPeers: number;
    tokensPerSecond: number;
    ethicsChecksPassed: number;
  }
  
  let metrics: SystemMetrics = {
    bufferFillPercent: 0,
    activeAdapter: 'none',
    syncPeers: 0,
    tokensPerSecond: 0,
    ethicsChecksPassed: 0,
  };
  
  let interval: number;
  
  onMount(async () => {
    // Poll metrics every 2 seconds
    interval = setInterval(async () => {
      metrics = await invoke('get_system_metrics');
    }, 2000);
  });
  
  onDestroy(() => {
    clearInterval(interval);
  });
</script>

<div class="status-hud">
  <!-- Buffer Status -->
  <div class="metric">
    <span class="label">Buffer</span>
    <div class="bar">
      <div class="fill" style="width: {metrics.bufferFillPercent}%"></div>
    </div>
    <span class="value">{metrics.bufferFillPercent}%</span>
  </div>
  
  <!-- Active Adapter -->
  <div class="metric">
    <span class="label">Mode</span>
    <span class="value adapter">{metrics.activeAdapter}</span>
  </div>
  
  <!-- P2P Sync -->
  <div class="metric">
    <span class="label">Peers</span>
    <span class="value">{metrics.syncPeers}</span>
  </div>
  
  <!-- Throughput -->
  <div class="metric">
    <span class="label">Speed</span>
    <span class="value">{metrics.tokensPerSecond} tok/s</span>
  </div>
  
  <!-- Ethics -->
  <div class="metric ethics">
    <span class="label">Genesis</span>
    <span class="value {metrics.ethicsChecksPassed > 0 ? 'active' : ''}">
      {metrics.ethicsChecksPassed > 0 ? '✓' : '○'}
    </span>
  </div>
</div>

<style>
  .status-hud {
    position: fixed;
    top: 1rem;
    right: 1rem;
    background: rgba(10, 10, 10, 0.8);
    border: 1px solid #00ff00;
    border-radius: 8px;
    padding: 1rem;
    font-family: 'Courier New', monospace;
    font-size: 0.875rem;
    backdrop-filter: blur(10px);
    box-shadow: 0 0 20px rgba(0, 255, 0, 0.3);
    z-index: 9999;
  }
  
  .metric {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.5rem;
  }
  
  .metric:last-child {
    margin-bottom: 0;
  }
  
  .label {
    color: #00ff00;
    min-width: 60px;
  }
  
  .value {
    color: #00ffff;
    font-weight: bold;
  }
  
  .value.adapter {
    text-transform: uppercase;
    color: #ff00ff;
  }
  
  .bar {
    flex: 1;
    height: 8px;
    background: rgba(0, 255, 0, 0.2);
    border-radius: 4px;
    overflow: hidden;
  }
  
  .fill {
    height: 100%;
    background: linear-gradient(90deg, #00ff00, #00ffff);
    transition: width 0.3s ease;
  }
  
  .ethics .value.active {
    color: #00ff00;
    text-shadow: 0 0 10px #00ff00;
  }
</style>
```

### Tauri Backend Commands
```rust
// src-tauri/src/commands.rs

#[derive(serde::Serialize)]
pub struct SystemMetrics {
    buffer_fill_percent: u8,
    active_adapter: String,
    sync_peers: u32,
    tokens_per_second: f32,
    ethics_checks_passed: u32,
}

#[tauri::command]
pub async fn get_system_metrics() -> Result<SystemMetrics, String> {
    // TODO: Get actual metrics from synapse-core
    Ok(SystemMetrics {
        buffer_fill_percent: 42,
        active_adapter: "personal".to_string(),
        sync_peers: 2,
        tokens_per_second: 15.3,
        ethics_checks_passed: 127,
    })
}
```

### Design Requirements
- **Position:** Top-right corner (fixed)
- **Transparency:** 80% background opacity
- **Update Rate:** 2 seconds (configurable)
- **Size:** Compact (~200px width)
- **Colors:**
  - Labels: Neon green (`#00ff00`)
  - Values: Cyan (`#00ffff`)
  - Adapter: Magenta (`#ff00ff`)
  - Background: Dark with blur

### Metrics Explained

| Metric | Source | Purpose |
|--------|--------|---------|
| **Buffer** | BufferPort | Shows how full short-term memory is |
| **Mode** | Current LoRA | Which "personality" is active |
| **Peers** | Libp2p | How many devices are syncing |
| **Speed** | LLM inference | Tokens generated per second |
| **Genesis** | GenesisBlock | Ethics checks passed (green ✓) |

---

**Assigned to:** Jules (Google)  
**Issue:** #11
