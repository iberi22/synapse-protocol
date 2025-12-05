# Dojo Component - Human Validation Minigame

## Overview
Svelte component for the "Dojo" - a gamified interface where users validate AI-generated summaries and teach the model ethical boundaries.

## Features (To Implement)
- [ ] Card-based UI for memory validation
- [ ] Swipe gestures (approve/reject)
- [ ] Score/points system
- [ ] Visual feedback animations
- [ ] Cyberpunk aesthetic

## Implementation Guide for Jules

### Component Structure
```svelte
<script lang="ts">
  // Props
  export let memoryNode: MemoryNode;
  export let onValidate: (nodeId: string, approved: boolean) => void;
  
  // State
  let score = 0;
  let streak = 0;
</script>

<div class="dojo-card">
  <!-- Memory content display -->
  <div class="memory-preview">
    {memoryNode.content}
  </div>
  
  <!-- Validation buttons -->
  <div class="actions">
    <button on:click={() => onValidate(memoryNode.id, false)}>
      ❌ Reject
    </button>
    <button on:click={() => onValidate(memoryNode.id, true)}>
      ✅ Approve
    </button>
  </div>
</div>

<style>
  .dojo-card {
    /* Cyberpunk styling */
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border: 2px solid #00ff00;
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 0 20px rgba(0, 255, 0, 0.5);
  }
</style>
```

### Integration with Tauri
```typescript
// src/lib/api.ts
import { invoke } from '@tauri-apps/api/tauri';

export async function getNextMemoryForValidation(): Promise<MemoryNode> {
  return await invoke('get_pending_validation');
}

export async function submitValidation(nodeId: string, approved: boolean) {
  await invoke('validate_memory', { nodeId, approved });
}
```

### Color Palette (Cyberpunk)
- Primary: `#00ff00` (Neon green)
- Secondary: `#ff00ff` (Neon magenta)
- Background: `#0a0a0a` (Dark)
- Accent: `#00ffff` (Cyan)

---

**Assigned to:** Jules (Google)  
**Issue:** #8
