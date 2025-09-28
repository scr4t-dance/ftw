import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/SCR4T/);
});

test('create event', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByRole('link', { name: 'Événements' }).click();
  await page.getByRole('link', { name: 'Créer un nouvel événement' }).click();
  await page.locator('input[name="name"]').click();
  await page.locator('input[name="name"]').fill('Test playwright');
  await page.locator('div').filter({ hasText: /^Date de fin$/ }).getByRole('textbox').fill('2025-09-25');
  await page.getByRole('button', { name: 'Valider l\'événement' }).click();
  await page.getByRole('link', { name: 'Accéder à l\'événement' }).click();
  await page.getByRole('textbox').click();
  await page.getByRole('textbox').fill('Competition Playwright 1');
  await page.locator('select[name="kind.0"]').selectOption('Strictly');
  await page.locator('select[name="category.0"]').selectOption('Advanced');
  await page.getByRole('button', { name: 'Créer la compétition' }).click();
  await page.getByRole('link', { name: 'Accéder à la compétition' }).click();
  // todo : correct competition loading before proceding further
});