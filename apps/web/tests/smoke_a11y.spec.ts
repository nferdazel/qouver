import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const routes = [
  '/',
  '/projects',
  '/projects/skyward',
  '/journal',
  '/journal/authoritative-go-simulations',
  '/about',
  '/contact',
];

for (const path of routes) {
  test(`smoke & a11y: ${path}`, async ({ page }) => {
    await page.goto(path);
    await expect(page.locator('a.skip-link')).toHaveAttribute('href', '#main');
    await expect(page.locator('header.site-header')).toBeVisible();
    await expect(page.locator('footer.site-footer')).toBeVisible();

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });
}

test('navigation links work', async ({ page }) => {
  await page.goto('/');
  await page.click('nav a[href="/projects"]');
  await expect(page).toHaveURL('/projects');
  await expect(page.locator('h1')).toContainText('Production Systems');

  await page.click('nav a[href="/journal"]');
  await expect(page).toHaveURL('/journal');
  await expect(page.locator('h1')).toContainText('Journal');
});
