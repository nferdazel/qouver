import { test, expect } from '@playwright/test';

// Guards the two content claims that shipped wrong on 2026-11-24: a read time
// that did not match its own body, and an article saying this site runs no
// client JavaScript while every page hydrated a SvelteKit bundle.
const ARTICLES = [
  '/journal/authoritative-go-simulations',
  '/journal/zero-js-static-jaspr',
  '/journal/systems-prospector-manifesto',
];

const CLAIMS = [
  /zero[- ]js/i,
  /\bjaspr\b/i,
  /\bdart\b/i,
  /no client-?side javascript/i,
  /no client javascript/i,
  /zero client js/i,
];

for (const route of ARTICLES) {
  test(`read time matches the body: ${route}`, async ({ page }) => {
    await page.goto(route);
    const body = await page.locator('.article-reader__body').innerText();
    const words = body.trim().split(/\s+/).filter(Boolean).length;
    const expected = Math.max(1, Math.round(words / 200));

    const meta = await page.locator('.article-reader__meta').innerText();
    const match = meta.match(/(\d+)\s*min read/i);
    expect(match, `no read time in "${meta}"`).not.toBeNull();
    const shown = Number(match![1]);
    expect(shown, `${words} words shown as ${shown} min`).toBe(expected);
  });

  test(`no false zero-JS or Jaspr claim: ${route}`, async ({ page }) => {
    await page.goto(route);
    const text = await page.locator('main').innerText();
    for (const claim of CLAIMS) {
      expect(claim.test(text), `"${claim}" still in the copy`).toBe(false);
    }
  });
}
