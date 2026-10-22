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

test('contact form handles submission lifecycle', async ({ page }) => {
  await page.goto('/contact');

  // Verify form fields are visible and bound
  const nameInput = page.locator('#contact-name');
  const emailInput = page.locator('#contact-email');
  const subjectInput = page.locator('#contact-subject');
  const messageInput = page.locator('#contact-message');
  const submitBtn = page.locator('button[type="submit"]');

  await expect(nameInput).toBeVisible();
  await expect(emailInput).toBeVisible();
  await expect(subjectInput).toBeVisible();
  await expect(messageInput).toBeVisible();
  await expect(submitBtn).toBeVisible();

  // Mock successful response
  await page.route('**/api/contact', async (route) => {
    await route.fulfill({
      status: 201,
      contentType: 'application/json',
      body: JSON.stringify({
        id: '123e4567-e89b-12d3-a456-426614174000',
        status: 'received',
        createdAt: '2026-10-22T14:30:00Z',
      }),
    });
  });

  await nameInput.fill('Sachiel Tester');
  await emailInput.fill('tester@example.com');
  await subjectInput.fill('Test dispatch subject');
  await messageInput.fill('This is a test message to verify the form submission lifecycle.');

  await submitBtn.click();

  // Verify success message
  await expect(page.locator('.form-alert--success')).toBeVisible();
  await expect(page.locator('.form-alert__title')).toContainText('Message received');

  // Reset by clicking "Send another dispatch"
  await page.click('button:has-text("Send another dispatch")');
  await expect(nameInput).toBeVisible();
  await expect(nameInput).toHaveValue('');
});
