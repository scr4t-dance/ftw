import { test, expect } from '@playwright/test';
import { faker } from '@faker-js/faker';

test('has title', async ({ page }) => {
  await page.goto('/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/SCR4T/);
});

test('create event', async ({ page }) => {

  const randomEventName = faker.string.alpha(10);
  const randomCompetitionName = faker.string.alpha(10);

  await page.goto('http://localhost:3000/');
  await page.getByRole('link', { name: 'Événements' }).click();
  await page.getByRole('link', { name: 'Créer un nouvel événement' }).click();
  await page.locator('input[name="name"]').click();
  await page.locator('input[name="name"]').fill(randomEventName);
  await page.locator('div').filter({ hasText: /^Date de début$/ }).getByRole('textbox').fill('2025-09-17');
  await page.locator('div').filter({ hasText: /^Date de fin$/ }).getByRole('textbox').fill('2025-09-26');
  await page.getByRole('button', { name: 'Valider l\'événement' }).click();
  await page.getByRole('link', { name: 'Accéder à l\'événement' }).click();
  await page.getByRole('link', { name: 'Créer une competition' }).click();
  await page.getByRole('textbox').click();
  await page.getByRole('textbox').fill(randomCompetitionName);
  await page.locator('select[name="kind.0"]').selectOption('Strictly');
  await page.locator('select[name="category.0"]').selectOption('Advanced');
  await page.getByRole('button', { name: 'Créer la compétition' }).click();
  await page.getByRole('link', { name: 'Accéder à la compétition' }).click();
  await page.getByRole('link', { name: 'Création Phase' }).click();
  await page.locator('select[name="round.0"]').selectOption('Prelims');
  await page.getByRole('button', { name: 'Créer la phase' }).click();
  await page.getByRole('link', { name: 'Accéder à la Phase' }).click();
  // todo correct phase before proceding further

});