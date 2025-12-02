<script lang="ts">
  import Terminal from '$lib/components/Terminal.svelte';
</script>

<svelte:head>
  <title>SYNAPSE</title>
</svelte:head>

<div class="app-container">
  <Terminal />
</div>

<style>
  .app-container {
    height: 100vh;
    width: 100vw;
    display: flex;
    justify-content: center;
    align-items: center;
  }
</style>
