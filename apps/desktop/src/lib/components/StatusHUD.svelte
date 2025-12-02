<script>
  export let cpuUsage = 0;
  export let memUsage = 0;
  export let p2pConnected = false;
  export let p2pPeers = 0;
  export let tokenBalance = 0;
  export let activityData = [];

  // Simple representation of the activity chart
  const chartChars = [' ', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
  $: activityChart = activityData.map(d => chartChars[d] || ' ').join('');
</script>

<div class="status-hud">
  <div class="header">
    <span class="indicator-synapse">◉</span> SYNAPSE v0.1.0
  </div>
  <div class="metrics-section">
    <div class="metric">
      <span class="label">CPU:</span>
      <div class="bar-container">
        <div class="bar" style="width: {cpuUsage}%"></div>
      </div>
      <span class="value">{cpuUsage}%</span>
    </div>
    <div class="metric">
      <span class="label">MEM:</span>
      <div class="bar-container">
        <div class="bar" style="width: {memUsage}%"></div>
      </div>
      <span class="value">{memUsage}%</span>
    </div>
    <div class="metric">
      <span class="label">P2P:</span>
      <span class="p2p-status {p2pConnected ? 'connected' : ''}">●</span>
      <span class="p2p-text">{p2pConnected ? `Connected (${p2pPeers})` : 'Disconnected'}</span>
    </div>
  </div>
  <div class="token-section">
    <div class="token-balance">TOKENS: {tokenBalance} ◆</div>
    <div class="activity-chart">
      {activityChart} (24h)
    </div>
  </div>
</div>

<style>
  .status-hud {
    --hud-bg: rgba(10, 25, 10, 0.85);
    --hud-border: #00ff00;
    --hud-text: #00ff00;
    --hud-accent: #ff00ff;
    --bar-bg: #1a3a1a;
    font-family: 'monospace', monospace;
    background-color: var(--hud-bg);
    color: var(--hud-text);
    border: 1px solid var(--hud-border);
    backdrop-filter: blur(5px);
    width: 280px;
    font-size: 14px;
    display: flex;
    flex-direction: column;
    box-shadow: 0 0 15px var(--hud-border);
  }

  .header, .metrics-section, .token-section {
    padding: 8px 12px;
  }

  .header {
    border-bottom: 1px solid var(--hud-border);
    font-weight: bold;
    display: flex;
    align-items: center;
  }

  .indicator-synapse {
    color: var(--hud-accent);
    margin-right: 8px;
    text-shadow: 0 0 5px var(--hud-accent);
  }

  .metrics-section, .token-section {
    border-top: 1px dashed rgba(0, 255, 0, 0.3);
  }

  .metric {
    display: grid;
    grid-template-columns: 40px 1fr 40px;
    align-items: center;
    margin-bottom: 6px;
  }

  .label {
    text-align: left;
  }

  .value {
    text-align: right;
  }

  .bar-container {
    background-color: var(--bar-bg);
    border: 1px solid var(--hud-text);
    height: 12px;
    margin: 0 8px;
    overflow: hidden;
  }

  .bar {
    background: var(--hud-text);
    height: 100%;
    box-shadow: 0 0 5px var(--hud-text);
    transition: width 0.3s ease-in-out;
  }

  .p2p-status {
    color: #ff0000; /* Disconnected by default */
    margin-right: 5px;
    text-shadow: 0 0 5px #ff0000;
  }

  .p2p-status.connected {
    color: var(--hud-text);
    text-shadow: 0 0 5px var(--hud-text);
  }

  .p2p-text {
    flex-grow: 1;
  }

  .token-balance {
    font-weight: bold;
    margin-bottom: 8px;
  }

  .activity-chart {
    text-align: center;
    font-size: 16px;
    letter-spacing: 2px;
  }
</style>
