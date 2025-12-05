# Terminal Component - Main Chat Interface

## Overview
The main chat interface component - terminal-style UI for conversing with the AI.

## Features (To Implement)
- [ ] Message history display (scrollable)
- [ ] Input field with multi-line support
- [ ] Typing indicators
- [ ] Code syntax highlighting (for AI responses)
- [ ] Message timestamps
- [ ] Avatar/role indicators (User vs AI)
- [ ] Cyberpunk terminal aesthetic

## Implementation Guide for Jules

### Component Structure
```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { invoke } from '@tauri-apps/api/tauri';
  
  interface Message {
    id: string;
    role: 'user' | 'assistant';
    content: string;
    timestamp: number;
  }
  
  let messages: Message[] = [];
  let input = '';
  let isLoading = false;
  let terminalElement: HTMLElement;
  
  async function sendMessage() {
    if (!input.trim()) return;
    
    // Add user message
    const userMessage: Message = {
      id: crypto.randomUUID(),
      role: 'user',
      content: input,
      timestamp: Date.now(),
    };
    messages = [...messages, userMessage];
    input = '';
    
    // Scroll to bottom
    scrollToBottom();
    
    // Get AI response
    isLoading = true;
    try {
      const response = await invoke<string>('chat', { 
        message: userMessage.content 
      });
      
      const aiMessage: Message = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: response,
        timestamp: Date.now(),
      };
      messages = [...messages, aiMessage];
    } catch (error) {
      console.error('Chat error:', error);
    } finally {
      isLoading = false;
      scrollToBottom();
    }
  }
  
  function scrollToBottom() {
    setTimeout(() => {
      if (terminalElement) {
        terminalElement.scrollTop = terminalElement.scrollHeight;
      }
    }, 100);
  }
  
  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  }
</script>

<div class="terminal">
  <!-- Message History -->
  <div class="messages" bind:this={terminalElement}>
    {#each messages as message (message.id)}
      <div class="message {message.role}">
        <div class="header">
          <span class="role">
            {message.role === 'user' ? '>' : '◇'}
          </span>
          <span class="timestamp">
            {new Date(message.timestamp).toLocaleTimeString()}
          </span>
        </div>
        <div class="content">
          {@html message.content}
        </div>
      </div>
    {/each}
    
    {#if isLoading}
      <div class="message assistant loading">
        <div class="header">
          <span class="role">◇</span>
          <span class="timestamp">thinking...</span>
        </div>
        <div class="content">
          <span class="cursor">▮</span>
        </div>
      </div>
    {/if}
  </div>
  
  <!-- Input Field -->
  <div class="input-container">
    <textarea
      bind:value={input}
      on:keydown={handleKeydown}
      placeholder="Enter message... (Shift+Enter for new line)"
      rows="3"
      disabled={isLoading}
    />
    <button on:click={sendMessage} disabled={isLoading || !input.trim()}>
      Send →
    </button>
  </div>
</div>

<style>
  .terminal {
    display: flex;
    flex-direction: column;
    height: 100vh;
    background: #0a0a0a;
    color: #00ff00;
    font-family: 'Courier New', monospace;
    overflow: hidden;
  }
  
  .messages {
    flex: 1;
    overflow-y: auto;
    padding: 2rem;
    scroll-behavior: smooth;
  }
  
  .message {
    margin-bottom: 1.5rem;
    animation: fadeIn 0.3s ease;
  }
  
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
  }
  
  .message.user {
    color: #00ffff;
  }
  
  .message.assistant {
    color: #00ff00;
  }
  
  .header {
    display: flex;
    gap: 1rem;
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
    opacity: 0.7;
  }
  
  .role {
    font-weight: bold;
  }
  
  .content {
    margin-left: 2rem;
    line-height: 1.6;
  }
  
  .loading .cursor {
    animation: blink 1s infinite;
  }
  
  @keyframes blink {
    0%, 50% { opacity: 1; }
    51%, 100% { opacity: 0; }
  }
  
  .input-container {
    display: flex;
    gap: 1rem;
    padding: 1rem 2rem;
    border-top: 1px solid #00ff00;
    background: rgba(0, 255, 0, 0.05);
  }
  
  textarea {
    flex: 1;
    background: #0a0a0a;
    border: 1px solid #00ff00;
    color: #00ffff;
    padding: 0.75rem;
    font-family: inherit;
    font-size: 1rem;
    resize: none;
    border-radius: 4px;
  }
  
  textarea:focus {
    outline: none;
    box-shadow: 0 0 10px rgba(0, 255, 0, 0.5);
  }
  
  textarea:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  button {
    background: linear-gradient(135deg, #00ff00, #00ffff);
    border: none;
    color: #0a0a0a;
    padding: 0.75rem 2rem;
    font-weight: bold;
    cursor: pointer;
    border-radius: 4px;
    transition: transform 0.2s;
  }
  
  button:hover:not(:disabled) {
    transform: scale(1.05);
  }
  
  button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
```

### Tauri Backend Commands
```rust
// src-tauri/src/commands.rs

use synapse_core::ports::LlmPort;

#[tauri::command]
pub async fn chat(
    message: String,
    state: tauri::State<'_, AppState>,
) -> Result<String, String> {
    let llm = &state.llm;
    
    // Get conversation context from buffer
    let context = get_recent_context(&state.buffer).await?;
    
    // Generate response
    let response = llm
        .generate(&format!("{}\nUser: {}\nAssistant:", context, message))
        .await
        .map_err(|e| e.to_string())?;
    
    // Store interaction in buffer
    store_interaction(&state.buffer, message, response.clone()).await?;
    
    Ok(response)
}
```

### Advanced Features (Phase 2)

#### 1. Code Syntax Highlighting
```typescript
// Use highlight.js or similar
import hljs from 'highlight.js';

function formatMessage(content: string): string {
  // Detect code blocks
  return content.replace(/```(\w+)?\n([\s\S]*?)```/g, (_, lang, code) => {
    const highlighted = hljs.highlight(code, { language: lang || 'plaintext' });
    return `<pre><code class="hljs">${highlighted.value}</code></pre>`;
  });
}
```

#### 2. Markdown Rendering
```bash
npm install marked
```

```typescript
import { marked } from 'marked';

function renderMarkdown(content: string): string {
  return marked.parse(content);
}
```

#### 3. Streaming Responses
```typescript
// For real-time token streaming
async function streamChat(message: string) {
  const stream = await invoke<Stream>('chat_stream', { message });
  
  for await (const chunk of stream) {
    // Append chunk to current message
    updateLastMessage(chunk);
  }
}
```

### Design Requirements
- **Font:** Courier New (monospace)
- **Colors:**
  - User messages: Cyan (`#00ffff`)
  - AI messages: Green (`#00ff00`)
  - Background: Black (`#0a0a0a`)
  - Input border: Green glow
- **Animations:**
  - Fade-in for new messages
  - Blinking cursor for loading state
  - Smooth scroll to bottom
- **Accessibility:**
  - Keyboard shortcuts (Enter to send, Shift+Enter for newline)
  - Screen reader support
  - High contrast text

### User Experience
- Messages appear with fade-in animation
- Auto-scroll to bottom on new message
- Typing indicator when AI is thinking
- Timestamps for context
- Multi-line input support

---

**Assigned to:** Jules (Google)  
**Issue:** #13
