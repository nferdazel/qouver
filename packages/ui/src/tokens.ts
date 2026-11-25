/**
 * Direction C design tokens for Qouver.
 *
 * The stylesheet in apps/web/static/styles.css is the single source for the
 * rendered values; this file mirrors them for anything that needs the numbers
 * in TypeScript. Keep the two in step: a token that exists here and nowhere in
 * the CSS is a lie.
 */
export const tokens = {
  colors: {
    white: '#FFFFFF',
    ink: '#0A0A0A',
    grey: '#E9E9E6',
    muted: '#4A4A4A',
    yellow: '#FFD400',
  },
  // Eight roles, nothing below 14px. Display and heading sizes clamp between
  // these bounds; the rest are fixed.
  type: {
    display: 'clamp(56px, 9vw, 120px)',
    headingL: 'clamp(30px, 3.4vw, 46px)',
    headingM: 'clamp(22px, 2.4vw, 32px)',
    title: '22px',
    body: '17px',
    bodyS: '15px',
    caption: '14px',
    label: '14px',
  },
  // Display tracking is per size, never zero.
  tracking: {
    display: '-0.045em',
    headingL: '-0.03em',
    headingM: '-0.02em',
    title: '-0.01em',
    label: '0.12em',
  },
  // 4 8 12 16 24 32 48 64 96 128
  spacing: [4, 8, 12, 16, 24, 32, 48, 64, 96, 128],
  fonts: {
    display: '"Anton", Impact, system-ui, sans-serif',
    body: '"Public Sans", system-ui, sans-serif',
    mono: 'ui-monospace, "SF Mono", Menlo, Consolas, monospace',
  },
  layout: {
    max: '90rem',
    maxDoc: '82rem',
    // Declared vertical lines at 1440, held to 0px spread.
    homeLines: [48, 504, 960],
    recordLines: [112, 422, 486],
  },
} as const;
