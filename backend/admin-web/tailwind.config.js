/** Couleurs et typo du theme "Hivernal & net" de l'application mobile. */
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Manrope', 'system-ui', 'sans-serif'],
      },
      colors: {
        ice: '#F3F6F9',
        ink: { DEFAULT: '#0E1C2B', light: '#E3EAF2' },
        slate: { 2: '#4A5A6B', 3: '#7D8A98' },
        line: '#DCE3EA',
        glacier: { DEFAULT: '#2F6FB0', light: '#E2EDF8' },
        signal: { DEFAULT: '#F26B1D', dark: '#C9520F', light: '#FDEBDF' },
        ok: { DEFAULT: '#1F9D63', light: '#E3F5EC' },
        warn: { DEFAULT: '#C98A06', light: '#FBF1D9' },
        danger: { DEFAULT: '#D64545', light: '#FBE6E6' },
        teal: { DEFAULT: '#0E8A9A', light: '#DFF3F5' },
      },
      boxShadow: {
        card: '0 2px 6px rgba(14, 28, 43, 0.05)',
        pop: '0 12px 28px rgba(14, 28, 43, 0.12)',
      },
    },
  },
  plugins: [],
};
