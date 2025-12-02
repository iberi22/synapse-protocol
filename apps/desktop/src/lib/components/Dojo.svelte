<script lang="ts">
  import { tweened } from 'svelte/motion';
  import { cubicOut } from 'svelte/easing';
  import { createEventDispatcher } from 'svelte';

  const dispatch = createEventDispatcher();

  // Mock data for the current validation task
  let question = "How do I fix a memory leak?";
  let answerA = "Check for unclosed references and ensure proper resource disposal in your code.";
  let answerB = "Restart your computer every hour and hope for the best.";

  // Reactive state
  let streak = 5;
  let earnedTokens = tweened(0, {
    duration: 400,
    easing: cubicOut,
  });
  let selected: 'A' | 'B' | null = null;
  let feedbackMessage = '';
  let isAnimating = false;
  let lastAnswerResult: 'correct' | 'incorrect' | null = null;

  async function handleSelection(choice: 'A' | 'B') {
    if (isAnimating) return;

    isAnimating = true;
    selected = choice;

    // Simulate API call and feedback
    await new Promise(resolve => setTimeout(resolve, 500));

    // In a real scenario, you'd get the correct answer from a backend
    const isCorrect = choice === 'A';

    if (isCorrect) {
      lastAnswerResult = 'correct';
      streak++;
      const reward = 10 + Math.floor(streak / 5); // Bonus for longer streaks
      feedbackMessage = `Correct!`;
      earnedTokens.set(reward);
      dispatch('updateTokens', { amount: reward });
    } else {
      lastAnswerResult = 'incorrect';
      streak = 0;
      feedbackMessage = 'Incorrect. Streak reset!';
      earnedTokens.set(0);
    }

    // Reset for next question after a delay
    setTimeout(() => {
      loadNextQuestion();
      selected = null;
      feedbackMessage = '';
      earnedTokens.set(0);
      isAnimating = false;
      lastAnswerResult = null;
    }, 1500);
  }

  function loadNextQuestion() {
    // Mock loading new data
    question = "What is the best way to handle asynchronous operations in Svelte?";
    answerA = "Using reactive stores and the `$:` syntax for derived state.";
    answerB = "Wrapping everything in `setTimeout` with a 0ms delay.";
  }
</script>

<div class="dojo-container">
  <div class="header">
    <span class="icon">🥋</span> DOJO - Train AI
  </div>
  <div class="question">
    Q: "{question}"
  </div>
  <div class="answers">
    <div
      class="answer-pane"
      class:selected={selected === 'A'}
      class:correct={selected === 'A' && lastAnswerResult === 'correct'}
      class:incorrect={selected === 'A' && lastAnswerResult === 'incorrect'}
    >
      <div class="answer-content">
        <span class="answer-label">A)</span>
        <p>{answerA}</p>
      </div>
      <button class="select-button" on:click={() => handleSelection('A')} disabled={isAnimating}>
        [SELECT A]
      </button>
    </div>
    <div
      class="answer-pane"
      class:selected={selected === 'B'}
      class:correct={selected === 'B' && lastAnswerResult === 'correct'}
      class:incorrect={selected === 'B' && lastAnswerResult === 'incorrect'}
    >
      <div class="answer-content">
        <span class="answer-label">B)</span>
        <p>{answerB}</p>
      </div>
      <button class="select-button" on:click={() => handleSelection('B')} disabled={isAnimating}>
        [SELECT B]
      </button>
    </div>
  </div>
  <div class="footer">
    <div class="streak">
      🔥 Streak: {streak}
    </div>
    <div class="reward" class:visible={feedbackMessage}>
      {#if lastAnswerResult === 'correct'}
        +{Math.floor($earnedTokens)} ◆ earned!
      {:else}
        {feedbackMessage}
      {/if}
    </div>
  </div>
</div>

<style>
  /* Base styles from previous step are assumed to be here */
  .dojo-container {
    font-family: 'Courier New', Courier, monospace;
    background-color: #1a1a1a;
    color: #00ff00;
    border: 2px solid #00ff00;
    border-radius: 8px;
    width: 600px;
    margin: 2rem auto;
    padding: 1rem;
    box-shadow: 0 0 15px rgba(0, 255, 0, 0.5);
    overflow: hidden;
  }

  .header {
    font-size: 1.5rem;
    font-weight: bold;
    text-align: center;
    border-bottom: 2px solid #00ff00;
    padding-bottom: 0.5rem;
    margin-bottom: 1rem;
  }

  .question {
    margin-bottom: 1rem;
    padding: 0.5rem;
    border: 1px dashed #00ff00;
  }

  .answers {
    display: flex;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .answer-pane {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    border: 1px solid #00ff00;
    padding: 1rem;
    transition: all 0.3s ease;
  }

  .answer-pane.selected {
    transform: scale(1.05);
    box-shadow: 0 0 20px rgba(0, 255, 255, 0.7);
    border-color: #00ffff;
  }

  .answer-pane.correct {
    background-color: rgba(0, 255, 0, 0.1);
    border-color: #00ff00;
  }

  .answer-pane.incorrect {
    background-color: rgba(255, 0, 0, 0.1);
    border-color: #ff0000;
  }

  .answer-content {
    margin-bottom: 1rem;
  }

  .answer-label {
    font-weight: bold;
  }

  .select-button {
    background-color: transparent;
    border: 2px solid #00ff00;
    color: #00ff00;
    padding: 0.5rem 1rem;
    cursor: pointer;
    font-family: inherit;
    font-size: 1rem;
    align-self: center;
    transition: all 0.2s;
  }

  .select-button:hover:not(:disabled) {
    background-color: #00ff00;
    color: #1a1a1a;
  }

  .select-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .footer {
    display: flex;
    justify-content: space-between;
    border-top: 2px solid #00ff00;
    padding-top: 0.5rem;
    font-size: 1.1rem;
    position: relative;
  }

  .reward {
    color: #ffff00;
    opacity: 0;
    transform: translateY(20px);
    transition: all 0.4s ease;
  }

  .reward.visible {
    opacity: 1;
    transform: translateY(0);
  }
</style>
