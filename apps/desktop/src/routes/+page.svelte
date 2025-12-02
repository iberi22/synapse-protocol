<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";

  let name = $state("");
  let greetMsg = $state("");

  async function greet(event: Event) {
    event.preventDefault();
    // Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
    greetMsg = await invoke("greet", { name });
  }
</script>

<main class="bg-background text-text min-h-screen flex flex-col items-center justify-center">
  <h1 class="text-5xl font-bold text-primary mb-8">Synapse Protocol</h1>

  <div class="flex space-x-8 mb-8">
    <a href="https://vitejs.dev" target="_blank">
      <img src="/vite.svg" class="w-24 h-24" alt="Vite Logo" />
    </a>
    <a href="https://tauri.app" target="_blank">
      <img src="/tauri.svg" class="w-24 h-24" alt="Tauri Logo" />
    </a>
    <a href="https://kit.svelte.dev" target="_blank">
      <img src="/svelte.svg" class="w-24 h-24" alt="SvelteKit Logo" />
    </a>
  </div>

  <p class="text-lg mb-8">Click on the Tauri, Vite, and SvelteKit logos to learn more.</p>

  <form class="flex space-x-4" onsubmit={greet}>
    <input
      id="greet-input"
      class="bg-background border border-border rounded-md px-4 py-2 text-text focus:outline-none focus:ring-2 focus:ring-primary"
      placeholder="Enter a name..."
      bind:value={name}
    />
    <button
      type="submit"
      class="bg-primary text-background font-bold rounded-md px-4 py-2 hover:bg-secondary transition-colors"
    >
      Greet
    </button>
  </form>

  {#if greetMsg}
    <p class="mt-8 text-lg">{greetMsg}</p>
  {/if}
</main>
