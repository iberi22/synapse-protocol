<script>
  import StatusHUD from './lib/components/StatusHUD.svelte';

  // Placeholder data for the metrics
  let cpuUsage = 78;
  let memUsage = 56;
  let p2pConnected = true;
  let p2pPeers = 3;
  let tokenBalance = 1247;
  let activityData = [2, 3, 5, 6, 7, 8, 7, 5, 3, 2];

</script>

<main>
  <StatusHUD
    {cpuUsage}
    {memUsage}
    {p2pConnected}
    {p2pPeers}
    {tokenBalance}
    {activityData}
  />
</main>

<style>
  main {
    background-color: #0a0a0a;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
  }
</style>
