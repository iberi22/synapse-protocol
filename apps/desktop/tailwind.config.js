/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        background: '#000000',
        primary: '#00F3FF',
        secondary: '#FF00FF',
        text: '#FFFFFF',
        border: '#1A1A1A',
      }
    },
  },
  plugins: [],
}