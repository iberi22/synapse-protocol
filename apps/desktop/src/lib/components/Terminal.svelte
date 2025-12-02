<script lang="ts">
  import { onMount } from 'svelte';
  import { marked } from 'marked';
  import DOMPurify from 'dompurify';

  type Message = {
    sender: 'USER' | 'AI';
    text: string;
    timestamp: number;
  };

  let messages: Message[] = [
    { sender: 'USER', text: 'What is the meaning of life?', timestamp: Date.now() - 1000 },
    { sender: 'AI', text: 'Based on my analysis, it is to create cool UIs.', timestamp: Date.now() }
  ];
  let userInput = '';
  let isAiTyping = false;
  let historyContainer: HTMLElement;

  onMount(() => {
    scrollToBottom();
  });

  function scrollToBottom() {
    if (historyContainer) {
      historyContainer.scrollTop = historyContainer.scrollHeight;
    }
  }

  async function handleSubmit() {
    if (userInput.trim() === '') return;

    // Add user message
    messages = [...messages, { sender: 'USER', text: userInput, timestamp: Date.now() }];
    userInput = '';
    scrollToBottom();

    // Simulate AI response
    isAiTyping = true;
    setTimeout(() => {
      messages = [...messages, { sender: 'AI', text: 'Thinking...', timestamp: Date.now() }];
      isAiTyping = false;
      scrollToBottom();
    }, 1500);
  }
</script>

<div class="terminal-container">
  <div class="history" bind:this={historyContainer}>
    {#each messages as message}
      <div class="message {message.sender.toLowerCase()}">
        <span class="prompt">{message.sender === 'USER' ? '>' : 'SYNAPSE:'}</span>
        <div class="text">
          {#if message.sender === 'AI'}
            {@html DOMPurify.sanitize(marked(message.text) as string)}
          {:else}
            {message.text}
          {/if}
        </div>
      </div>
    {/each}
    {#if isAiTyping}
      <div class="message ai-typing">
        <span class="prompt">SYNAPSE:</span>
        <div class="typing-indicator">▋</div>
      </div>
    {/if}
  </div>
  <div class="input-area">
    <span class="prompt">></span>
    <input
      type="text"
      bind:value={userInput}
      on:keydown={(e) => e.key === 'Enter' && handleSubmit()}
      placeholder="_"
      autofocus
    />
  </div>
</div>

<style>
  .terminal-container {
    display: flex;
    flex-direction: column;
    height: 100%;
    width: 100%;
    background-color: #0d0208;
    color: #00ff41;
    font-family: 'Courier New', Courier, monospace;
    border: 2px solid #00ff41;
    box-shadow: 0 0 15px #00ff41;
  }

  .history {
    flex-grow: 1;
    overflow-y: auto;
    padding: 1rem;
    scrollbar-width: none; /* Firefox */
  }

  .history::-webkit-scrollbar {
    display: none; /* Safari and Chrome */
  }

  .message {
    display: flex;
    margin-bottom: 0.5rem;
  }

  .prompt {
    margin-right: 0.5rem;
    white-space: nowrap;
  }

  .message.ai .text {
    color: #f3f3f3;
  }

  .text {
    white-space: pre-wrap;
    word-break: break-word;
  }

  .input-area {
    display: flex;
    align-items: center;
    padding: 0.5rem 1rem;
    border-top: 2px solid #00ff41;
  }

  input {
    flex-grow: 1;
    background: transparent;
    border: none;
    color: #00ff41;
    font-family: inherit;
    font-size: 1rem;
  }

  input:focus {
    outline: none;
  }

  .ai-typing .typing-indicator {
    animation: blink 1s infinite;
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0; }
  }
</style>
