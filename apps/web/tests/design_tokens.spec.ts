import { test, expect } from '@playwright/test';
import type { Page } from '@playwright/test';

const ROUTES = [
  '/',
  '/projects',
  '/projects/skyward',
  '/projects/majadu',
  '/projects/sds',
  '/projects/mdef',
  '/journal',
  '/journal/authoritative-go-simulations',
  '/journal/zero-js-static-jaspr',
  '/journal/systems-prospector-manifesto',
  '/about',
  '/contact',
  '/404',
];

// Every visible text node on the page, with the font size it actually computed.
async function measureFontSizes(page: Page) {
  return page.evaluate(() => {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const out: Array<{ text: string; px: number; tag: string; cls: string }> = [];
    let node = walker.nextNode();
    while (node) {
      const current = node;
      node = walker.nextNode();
      const text = (current.textContent ?? '').trim();
      if (!text) continue;
      const el = current.parentElement;
      if (!el) continue;
      const style = getComputedStyle(el);
      if (style.display === 'none' || style.visibility === 'hidden') continue;
      const box = el.getBoundingClientRect();
      if (box.width === 0 || box.height === 0) continue;
      // Skip chrome injected by the test runner.
      if (el.closest('nextjs-portal,#__next-build-watcher')) continue;
      out.push({
        text: text.slice(0, 40),
        px: parseFloat(style.fontSize),
        tag: el.tagName.toLowerCase(),
        cls: el.className?.toString().slice(0, 60) ?? '',
      });
    }
    return out;
  });
}

const MIN_PX = 14;

for (const route of ROUTES) {
  test(`type floor >= ${MIN_PX}px: ${route}`, async ({ page }) => {
    await page.goto(route);
    const sizes = await measureFontSizes(page);
    const under = sizes.filter((s) => s.px < MIN_PX - 0.01);
    expect(under, `text under ${MIN_PX}px: ${JSON.stringify(under.slice(0, 8))}`).toEqual([]);
  });
}

test('no letter-spacing/tracking regression: every uppercase label has tracking', async ({ page }) => {
  await page.goto('/');
  const bad = await page.evaluate(() => {
    const out = [];
    for (const el of document.querySelectorAll('body *')) {
      const s = getComputedStyle(el);
      const text = (el.textContent || '').trim();
      if (!text || el.children.length) continue;
      if (s.textTransform !== 'uppercase') continue;
      const ls = parseFloat(s.letterSpacing);
      if (!Number.isFinite(ls) || ls <= 0) {
        out.push({ text: text.slice(0, 30), ls: s.letterSpacing });
      }
    }
    return out;
  });
  expect(bad).toEqual([]);
});

// One campaign: every primary interactive element changes something other than
// just colour on hover. Captures a rest/hover diff of geometry and ink.
const HOVER_TARGETS = [
  { route: '/', sel: '.rd-ledger-row' },
  { route: '/', sel: '.rd-ledger-row__name a' },
  { route: '/', sel: '.brand' },
  { route: '/', sel: '.nav__link' },
  { route: '/', sel: '.rd-btn' },
  { route: '/', sel: '.rd-link-line' },
  { route: '/', sel: '.rd-mailto' },
  { route: '/projects', sel: '.rd-ledger-row' },
  { route: '/projects', sel: '.rd-btn--ghost' },
  // The contact rows put their class on the anchor itself, not on a wrapper.
  // A selector waiting for a descendant there matched nothing, which is how the
  // contact links shipped with no hover at all.
  { route: '/contact', sel: 'a.contact-row__value' },
  { route: '/contact', sel: 'a.contact-row__value >> nth=1' },
];

for (const { route, sel } of HOVER_TARGETS) {
  test(`hover is more than a colour swap: ${route} ${sel}`, async ({ page }) => {
    await page.goto(route);
    const target = page.locator(sel).first();
    // Scroll first. Playwright's hover() scrolls the element into view, and a
    // viewport-relative box then moves on its own, which a diff reads as a
    // state change even when nothing changed. Document-relative boxes and a
    // pre-scrolled element keep the measurement about the element.
    await target.scrollIntoViewIfNeeded();
    const measure = () =>
      target.evaluate((el) => {
        const snap = (node: Element, tag: string) => {
          const s = getComputedStyle(node);
          const before = getComputedStyle(node, '::before');
          const after = getComputedStyle(node, '::after');
          const r = node.getBoundingClientRect();
          return {
            [`${tag}.color`]: s.color,
            [`${tag}.bg`]: s.backgroundColor,
            [`${tag}.backgroundSize`]: s.backgroundSize,
            [`${tag}.borderColor`]: s.borderBottomColor,
            [`${tag}.textDecorationThickness`]: s.textDecorationThickness,
            [`${tag}.transform`]: s.transform,
            [`${tag}.before.transform`]: before.transform,
            [`${tag}.before.backgroundSize`]: before.backgroundSize,
            [`${tag}.before.opacity`]: before.opacity,
            [`${tag}.after.transform`]: after.transform,
            [`${tag}.after.backgroundSize`]: after.backgroundSize,
            [`${tag}.w`]: Math.round(r.width * 100) / 100,
            [`${tag}.h`]: Math.round(r.height * 100) / 100,
            [`${tag}.x`]: Math.round((r.x + window.scrollX) * 100) / 100,
            [`${tag}.y`]: Math.round((r.y + window.scrollY) * 100) / 100,
          };
        };
        const out = { ...snap(el, 'self') };
        let i = 0;
        for (const child of el.querySelectorAll('*')) {
          Object.assign(out, snap(child, `c${i++}`));
          if (i > 4) break;
        }
        return out;
      });

    const before = await measure();
    await target.hover();
    await page.waitForTimeout(400);
    const after = await measure();
    const changed = Object.keys(before).filter(
      (k) => JSON.stringify(before[k]) !== JSON.stringify(after[k]),
    );
    const isColour = (k: string) => /\.(color|bg|borderColor)$/.test(k);
    const colourOnly = changed.every(isColour);
    expect(changed.length, 'hover changes nothing').toBeGreaterThan(0);
    expect(colourOnly, `only colour changed (${changed.join(',')})`).toBe(false);
  });
}

// Tap targets: WCAG 2.2 AA asks for 24x24 CSS px (2.5.8). The audit listed five
// under-size back links; measure the whole page instead of trusting the list.
for (const route of ROUTES) {
  test(`tap targets >= 24px: ${route}`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto(route);
    const small = await page.evaluate(() => {
      const out = [];
      const els = document.querySelectorAll('a, button, [role="button"], input, select, textarea');
      for (const el of els) {
        const s = getComputedStyle(el);
        if (s.display === 'none' || s.visibility === 'hidden') continue;
        const r = el.getBoundingClientRect();
        if (r.width === 0 || r.height === 0) continue;
        // An inline link inside a sentence is exempt by 2.5.8.
        if (s.display === 'inline' && el.closest('p, li') && !el.classList.contains('link')) continue;
        if (r.width < 24 || r.height < 24) {
          out.push({
            tag: el.tagName.toLowerCase(),
            cls: el.className?.toString().slice(0, 50) ?? '',
            text: (el.textContent || '').trim().slice(0, 30),
            w: Math.round(r.width),
            h: Math.round(r.height),
          });
        }
      }
      return out;
    });
    expect(small, JSON.stringify(small)).toEqual([]);
  });
}

// Heading order: no level may be skipped on the way down.
for (const route of ROUTES) {
  test(`heading order: ${route}`, async ({ page }) => {
    await page.goto(route);
    const levels = await page.evaluate(() =>
      Array.from(document.querySelectorAll('h1,h2,h3,h4,h5,h6'))
        .filter((el) => {
          const s = getComputedStyle(el);
          const r = el.getBoundingClientRect();
          return s.display !== 'none' && s.visibility !== 'hidden' && r.height > 0;
        })
        .map((el) => ({
          level: Number(el.tagName[1]),
          text: (el.textContent || '').trim().slice(0, 40),
        })),
    );
    expect(levels.filter((l) => l.level === 1).length, 'exactly one h1').toBe(1);
    for (let i = 1; i < levels.length; i++) {
      const prev = levels[i - 1];
      const cur = levels[i];
      if (!prev || !cur) continue;
      expect(
        cur.level - prev.level,
        `skipped from h${prev.level} to h${cur.level} at "${cur.text}"`,
      ).toBeLessThanOrEqual(1);
    }
  });
}

// Spacing: every gap/padding/margin in the stylesheet resolves to a token on
// the 4px ladder (2px half-step allowed). Rendered px is the wrong probe here
// because clamp() with a vw term lands between steps at any single viewport.
test('spacing literals are all on the token ladder', async () => {
  const fs = await import('node:fs/promises');
  const path = await import('node:path');
  const cssPath = path.resolve('static/styles.css');
  const css = await fs.readFile(cssPath, 'utf8');

  const TOKENS = new Set([
    '0', '0.125rem', '0.25rem', '0.375rem', '0.5rem', '0.75rem', '1rem', '1.25rem',
    '1.5rem', '1.75rem', '2rem', '2.5rem', '3rem', '3.5rem', '4rem', '5rem', '6rem', '7rem',
  ]);

  const offenders = [];
  for (const decl of css.matchAll(/^\s*(gap|row-gap|column-gap|padding|padding-block|padding-inline|padding-top|padding-bottom|padding-left|padding-right|margin|margin-block|margin-inline|margin-top|margin-bottom|margin-left|margin-right):\s*([^;]+);/gm)) {
    const [, prop, raw] = decl;
    if (!prop || !raw) continue;
    const value = raw.trim();
    // clamp() and calc() are rhythm primitives; em values follow their parent type.
    if (/clamp\(|calc\(/.test(value) || /em\b/.test(value)) continue;
    for (const part of value.split(/\s+/)) {
      if (!part || TOKENS.has(part)) continue;
      if (/^var\(--s-/.test(part) || /^var\(--pad-/.test(part) || /^var\(--gut/.test(part)) continue;
      if (/^\d+%$/.test(part) || part === 'auto') continue;
      offenders.push(`${prop}: ${value}`);
      break;
    }
  }
  expect(offenders, JSON.stringify(offenders.slice(0, 12))).toEqual([]);
});

// The token definitions themselves: type floor and the ladder.
test('type tokens have a 14px floor and no orphans', async () => {
  const fs = await import('node:fs/promises');
  const path = await import('node:path');
  const css = await fs.readFile(path.resolve('static/styles.css'), 'utf8');
  const rootStart = css.indexOf(':root {');
  const rootEnd = css.indexOf('/* ------', rootStart);
  const root = css.slice(rootStart, rootEnd === -1 ? undefined : rootEnd);
  const steps = [...root.matchAll(/--step[\w-]*:\s*([^;]+);/g)].flatMap((m) =>
    m[1] ? [m[1].trim()] : [],
  );
  expect(steps.length).toBeGreaterThan(3);
  for (const step of steps) {
    if (step.startsWith('clamp(')) continue;
    const rem = parseFloat(step);
    const px = /rem/.test(step) ? rem * 16 : rem;
    expect(px, `--step ${step} is under the 14px floor`).toBeGreaterThanOrEqual(13.99);
  }
});

// No horizontal scroll at any width, with a hover state applied, because the
// hover bar and the long labels are where overflow usually appears.
for (const { label, width, height } of [
  { label: '320', width: 320, height: 568 },
  { label: '360', width: 360, height: 740 },
  { label: '390', width: 390, height: 844 },
  { label: '768', width: 768, height: 1024 },
  { label: '1440', width: 1440, height: 900 },
]) {
  test(`no horizontal overflow at ${label}px`, async ({ page }) => {
    await page.setViewportSize({ width, height });
    for (const route of ROUTES) {
      await page.goto(route);
      const row = page.locator('.rd-ledger-row').first();
      if (await row.count()) {
        await row.hover();
        await page.waitForTimeout(280);
      }
      const { sw, cw } = await page.evaluate(() => ({
        sw: document.documentElement.scrollWidth,
        cw: document.documentElement.clientWidth,
      }));
      expect(sw, `overflow at ${route} (${sw} > ${cw})`).toBeLessThanOrEqual(cw);
    }
  });
}
