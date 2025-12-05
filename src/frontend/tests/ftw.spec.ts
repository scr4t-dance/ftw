import { test, expect } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { DivisionItem, DivisionsItem, type Dancer, type DancerId } from '~/hookgen/model';

test('has title', async ({ page }) => {
  await page.goto('/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/SCR4T/);
});

function create_dancer(as_leader: DivisionsItem, as_follower: DivisionsItem) {
  const first_name = faker.string.alpha(10);
  const last_name = faker.string.alpha(10);

  return {
    first_name: first_name,
    last_name: last_name,
    as_leader: [as_leader],
    as_follower: [as_follower],
    birthday: { year: 2025, month: 10, day: 4 },
    email: `${first_name}.${last_name}@scrat.fr`,
  } satisfies Dancer;
}

test('create event', async ({ page }) => {

  test.slow();

  const randomEventName = faker.string.alpha(10);
  const randomCompetitionName = faker.string.alpha(10);

  const dancer_array = [
    create_dancer(DivisionsItem.Novice, DivisionsItem.None),
    create_dancer(DivisionsItem.None, DivisionsItem.Novice),
    create_dancer(DivisionsItem.Intermediate, DivisionsItem.None),
    create_dancer(DivisionsItem.None, DivisionsItem.Novice_Intermediate),
  ];

  await page.goto('http://localhost:3000/');

  await page.getByRole('link', { name: 'Se connecter' }).click();
  await page.locator('input[name="email"]').click();
  await page.locator('input[name="email"]').fill('test');
  await page.locator('input[name="email"]').press('Tab');
  await page.locator('input[name="password"]').fill('test');
  await page.locator('input[name="password"]').press('Enter');
  await page.getByRole('button', { name: 'Login' }).click();

  const admin_home_locator = page.getByRole('contentinfo').getByRole('link', { name: 'Admin' });
  // création compétiteurs
  await admin_home_locator.click();
  await page.getByRole('link', { name: 'Dancers' }).click();
  await page.getByRole('link', { name: 'Créer un-e nouvel-le compé' }).click();
  await page.locator('input[name="last_name"]').click();
  await page.locator('input[name="last_name"]').fill(dancer_array[0].last_name);
  await page.locator('input[name="last_name"]').press('Tab');
  await page.locator('input[name="first_name"]').fill(dancer_array[0].first_name);
  await page.locator('input[name="first_name"]').press('Tab');
  await page.locator('input[name="email"]').fill(dancer_array[0].email);
  await page.locator('input[name="email"]').press('Tab');
  await page.locator('input[type="date"]').fill('2025-11-04');
  await page.locator('select[name="as_leader.0"]').selectOption(dancer_array[0].as_leader[0]);
  await page.locator('select[name="as_follower.0"]').selectOption(dancer_array[0].as_follower[0]);
  await page.getByRole('button', { name: 'Nouveau' }).click();
  const dancer_0_link = await page.getByRole('link', { name: 'Accéder à la page de la' }).getAttribute("href");
  const dancer_0_id = Number(dancer_0_link?.match(/\d+/)?.[0]) as DancerId;

  await page.locator('input[name="last_name"]').click();
  await page.locator('input[name="last_name"]').fill(dancer_array[1].last_name);
  await page.locator('input[name="last_name"]').press('Tab');
  await page.locator('input[name="first_name"]').fill(dancer_array[1].first_name);
  await page.locator('input[name="first_name"]').press('Tab');
  await page.locator('input[name="email"]').fill(dancer_array[1].email);
  await page.locator('input[name="email"]').press('Tab');
  await page.locator('input[type="date"]').fill('2025-11-04');
  await page.locator('select[name="as_leader.0"]').selectOption(dancer_array[1].as_leader[0]);
  await page.locator('select[name="as_follower.0"]').selectOption(dancer_array[1].as_follower[0]);
  await page.getByRole('button', { name: 'Nouveau' }).click();
  const dancer_1_link = await page.getByRole('link', { name: 'Accéder à la page de la' }).getAttribute("href");
  const dancer_1_id = Number(dancer_1_link?.match(/\d+/)?.[0]) as DancerId;

  await page.locator('input[name="last_name"]').click();
  await page.locator('input[name="last_name"]').fill(dancer_array[2].last_name);
  await page.locator('input[name="last_name"]').press('Tab');
  await page.locator('input[name="first_name"]').fill(dancer_array[2].first_name);
  await page.locator('input[name="first_name"]').press('Tab');
  await page.locator('input[name="email"]').fill(dancer_array[2].email);
  await page.locator('input[name="email"]').press('Tab');
  await page.locator('input[type="date"]').fill('2025-11-04');
  await page.locator('select[name="as_leader.0"]').selectOption(dancer_array[2].as_leader[0]);
  await page.locator('select[name="as_follower.0"]').selectOption(dancer_array[2].as_follower[0]);
  await page.getByRole('button', { name: 'Nouveau' }).click();
  const dancer_2_link = await page.getByRole('link', { name: 'Accéder à la page de la' }).getAttribute("href");
  const dancer_2_id = Number(dancer_2_link?.match(/\d+/)?.[0]) as DancerId;

  await page.locator('input[name="last_name"]').click();
  await page.locator('input[name="last_name"]').fill(dancer_array[3].last_name);
  await page.locator('input[name="last_name"]').press('Tab');
  await page.locator('input[name="first_name"]').fill(dancer_array[3].first_name);
  await page.locator('input[name="first_name"]').press('Tab');
  await page.locator('input[name="email"]').fill(dancer_array[3].email);
  await page.locator('input[name="email"]').press('Tab');
  await page.locator('input[type="date"]').fill('2025-11-04');
  await page.locator('select[name="as_leader.0"]').selectOption(dancer_array[3].as_leader[0]);
  await page.locator('select[name="as_follower.0"]').selectOption(dancer_array[3].as_follower[0]);
  await page.getByRole('button', { name: 'Nouveau' }).click();
  const dancer_3_link = await page.getByRole('link', { name: 'Accéder à la page de la' }).getAttribute("href");
  const dancer_3_id = Number(dancer_3_link?.match(/\d+/)?.[0]) as DancerId;

  // création évent et compétition
  await admin_home_locator.click();
  await page.getByRole('link', { name: 'Events' }).click();
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


  // création dossards
  await page.getByRole('link', { name: 'Competition', exact: true }).click();
  await page.locator('input[name="bib"]').click();
  await page.locator('input[name="bib"]').fill('101');
  await page.locator('input[name="target.target"]').click();
  await page.locator('input[name="target.target"]').fill(String(dancer_0_id));
  await page.getByRole('listbox').selectOption('Follower');
  await page.getByRole('button', { name: 'Inscrire un-e compétiteurice' }).click();
  await page.getByText('✅ Bib ajoutée avec succès.').click();
  await page.locator('input[name="bib"]').click();
  await page.locator('input[name="bib"]').fill('102');
  await page.locator('input[name="target.target"]').click();
  await page.locator('input[name="target.target"]').fill(String(dancer_1_id));
  await page.getByRole('listbox').selectOption('Leader');
  await page.getByRole('button', { name: 'Inscrire un-e compétiteurice' }).click();
  await page.locator('input[name="bib"]').click();
  await page.locator('input[name="bib"]').fill('103');
  await page.locator('input[name="target.target"]').click();
  await page.locator('input[name="target.target"]').fill(String(dancer_2_id));
  await page.getByRole('listbox').selectOption('Follower');
  await page.getByRole('button', { name: 'Inscrire un-e compétiteurice' }).click();
  await page.locator('input[name="bib"]').click();
  await page.locator('input[name="bib"]').fill('104');
  await page.locator('input[name="target.target"]').click();
  await page.locator('input[name="target.target"]').fill(String(dancer_3_id));
  await page.getByRole('listbox').selectOption('Leader');
  await page.getByRole('button', { name: 'Inscrire un-e compétiteurice' }).click();

  // création prelims
  await admin_home_locator.click();
  await page.getByRole('link', { name: 'Events' }).click();
  await page.getByRole('link', { name: randomEventName }).click();
  await page.getByRole('link', { name: randomCompetitionName }).click();
  await page.getByRole('link', { name: 'Création Phase' }).click();
  // unknown race condition in webkit requires a 1 second wait
  // Prelim is correctly created, but is not shown on screen, and test fails
  await page.waitForTimeout(1000);
  //const selector = page.locator('select[name="round.0"] > option');
  //console.log(await selector.allInnerTexts());
  await page.locator('select[name="round.0"]').selectOption('Prelims');
  //await expect(page.locator('select[name="round.0"]')).toHaveValue('Prelims');
  await page.getByRole('button', { name: 'Créer la phase' }).click();
  await page.getByRole('link', { name: 'Accéder à la Phase' }).click();

  // add judges to prelims
  await page.getByRole('link', { name: 'Modifier les Juges' }).click();
  await page.getByRole('button', { name: 'append' }).first().click();
  await page.getByRole('cell', { name: 'Delete' }).getByRole('spinbutton').click();
  await page.getByRole('cell', { name: 'Delete' }).getByRole('spinbutton').fill(String(dancer_0_id));
  await page.getByRole('table').filter({ hasText: 'DancerIDPrénomNomappend' }).getByRole('button').click();
  await page.getByRole('spinbutton').nth(2).click();
  await page.getByRole('spinbutton').nth(2).fill(String(dancer_1_id));
  await page.getByRole('button', { name: 'Mettre à jour les juges' }).click();
  // TODO: check new judges are still visible
  await page.getByRole('link', { name: 'Juges', exact: true }).click();
  await expect(page.getByRole('link', { name: dancer_array[0].first_name })).toHaveCount(1);
  await expect(page.getByRole('link', { name: dancer_array[1].first_name })).toHaveCount(1);

  // création finales
  await admin_home_locator.click();
  await page.getByRole('link', { name: 'Events' }).click();
  await page.getByRole('link', { name: randomEventName }).click();
  await page.getByRole('link', { name: randomCompetitionName }).click();
  await page.getByRole('link', { name: 'Création Phase' }).click();
  // unknown race condition in webkit requires a 1 second wait
  // Prelim is correctly created, but is not shown on screen, and test fails
  await page.waitForTimeout(1000);
  //const selector = page.locator('select[name="round.0"] > option');
  //console.log(await selector.allInnerTexts());
  await page.locator('select[name="round.0"]').selectOption('Finals');
  //await expect(page.locator('select[name="round.0"]')).toHaveValue('Prelims');
  await page.getByRole('button', { name: 'Créer la phase' }).click();
  await page.getByRole('link', { name: 'Accéder à la Phase' }).click();

  // add judges to finals
  await page.getByRole('link', { name: 'Modifier les Juges' }).click();
  await page.getByRole('combobox').selectOption('couple');
  await page.getByRole('button', { name: 'append' }).click();
  await page.getByRole('button', { name: 'append' }).click();
  await page.getByRole('row').nth(1).getByRole('spinbutton').click();
  await page.getByRole('row').nth(1).getByRole('spinbutton').fill(String(dancer_0_id));
  await page.getByRole('row').nth(2).getByRole('spinbutton').click();
  await page.getByRole('row').nth(2).getByRole('spinbutton').fill(String(dancer_1_id));
  await page.getByRole('button', { name: 'Mettre à jour les juges' }).click();
  // TODO: check new judges are still visible
  await page.getByRole('link', { name: 'Juges', exact: true }).click();
  await expect(page.getByRole('link', { name: dancer_array[0].first_name })).toHaveCount(1);
  await expect(page.getByRole('link', { name: dancer_array[1].first_name })).toHaveCount(1);



  await admin_home_locator.click();
  // for webkit
  await page.waitForTimeout(250);
  await page.getByRole('link', { name: 'Events' }).click();
  await page.getByRole('link', { name: randomEventName }).click();
  await page.getByRole('link', { name: randomCompetitionName }).click();

  // cofngiuration heats
  await page.getByRole('link', { name: `Prelims ${randomCompetitionName}` }).click();
  await page.getByRole('link', { name: 'Poules', exact: true  }).click();
  await page.getByRole('button', { name: 'Insérer les dossards dans la Poule 0' }).click();
  await page.getByText('✅ Dossards insérés dans la Poule 0 !').click();
  await page.locator('input[name="min_number_of_targets"]').click();
  await page.locator('input[name="min_number_of_targets"]').fill('2');
  await page.locator('input[name="max_number_of_targets"]').click();
  await page.locator('input[name="max_number_of_targets"]').fill('2');
  await page.getByRole('button', { name: 'Initialiser les Heats' }).click();
  await page.getByText('✅ Dancers has been added').click();

  // remplissage artefacts
  function get_name(dancer: Dancer) {
    return `${dancer.first_name} ${dancer.last_name}`;
  }
  await page.getByRole('link', { name: 'Espace Scoreur' }).click();
  await page.getByRole('table').first()
    .getByRole('row').first()
    .getByRole('link', { name: dancer_array[0].first_name })
    .click();
  await page.getByRole('row', { name: dancer_array[2].first_name }).getByRole('spinbutton').click();
  await page.getByRole('row', { name: dancer_array[2].first_name }).getByRole('spinbutton').fill('3');
  await page.getByRole('row', { name: dancer_array[0].first_name }).getByRole('spinbutton').click();
  await page.getByRole('row', { name: dancer_array[0].first_name }).getByRole('spinbutton').fill('1');
  await page.getByRole('button', { name: 'Mettre à jour les artefacts' }).click();
  await page.getByRole('button', { name: 'Réinitialiser' }).click();
  // todo check artefacts
  await page.getByRole('link', { name: 'Espace Scoreur' }).click();
  await page.getByRole('table').nth(1)
    .getByRole('row').first()
    .getByRole('link', { name: dancer_array[1].first_name })
    .click();
  await page.getByRole('row', { name: dancer_array[3].first_name }).getByRole('spinbutton').click();
  await page.getByRole('row', { name: dancer_array[3].first_name }).getByRole('spinbutton').fill('2');
  await page.getByRole('row', { name: dancer_array[1].first_name }).getByRole('spinbutton').click();
  await page.getByRole('row', { name: dancer_array[1].first_name }).getByRole('spinbutton').fill('3');
  await page.getByRole('button', { name: 'Mettre à jour les artefacts' }).click();

  // ranks
  await page.getByRole('link', { name: 'Classement' }).click();
  await expect(page.getByText('Nombre de Target à passer à la phase suivante')).toBeVisible();
  await page.getByRole('spinbutton').fill('1');
  await page.getByRole('button', { name: 'Passer à la phase suivante' }).click();
  await expect(page.getByText("✅ 1 dancers has been transfered")).toHaveText("✅ 1 dancers has been transfered to next phase")

  await admin_home_locator.click();
  // for webkit
  await page.waitForTimeout(250);
  await page.getByRole('link', { name: 'Events' }).click();
  await page.getByRole('link', { name: randomEventName }).click();
  await page.getByRole('link', { name: randomCompetitionName }).click();
  await page.getByRole('link', { name: 'Finals' }).click();

  await page.getByRole('link', { name: 'Modifier les paramètres de la Phase', exact: true }).click();
  await page.locator('select[name="judge_artefact_descr.artefact"]').selectOption('ranking');
  await page.locator('select[name="head_judge_artefact_descr.artefact"]').selectOption('ranking');
  await page.locator('select[name="ranking_algorithm.algorithm"]').selectOption('ranking');
  await page.getByRole('button', { name: 'Mettre à jour la phase' }).click();
  await expect(page.getByText('✅ Phase "Finals" avec')).toContainText("mis à jour avec succès.");

  await page.getByRole('link', { name: 'Poules', exact: true  }).click();
  await page.getByRole('link', { name: 'Appairage' }).click();

  await page.locator('select[name="target.role"]').click();
  await page.locator('select[name="target.role"]').selectOption('Leader');
  await page.getByRole('combobox', { name: 'Leader' }).click();
  await page.getByText(dancer_array[3].first_name).click();
  await page.getByRole('button', { name: 'Ajouter un-e nouvelle compé' }).click();
  await page.locator('select[name="target.role"]').selectOption('Follower');
  await page.getByRole('combobox', { name: 'Follower' }).click();
  await page.getByText(dancer_array[0].first_name).click();
  await page.getByRole('button', { name: 'Ajouter un-e nouvelle compé' }).click();

  await page.getByRole('button', { name: 'Convertir en poules de coupé' }).click();
  await page.getByRole('button', { name: 'Modifier les couples' }).click();
  await page.locator('select[name="0"]').selectOption(String(dancer_2_id));
  await page.locator('select[name="1"]').selectOption(String(dancer_0_id));
  await page.getByRole('button', { name: 'Enregistrer les nouveaux' }).nth(1).click();

  await page.getByRole('link', { name: 'Poules', exact: true  }).click();
  await page.locator('input[name="min_number_of_targets"]').click();
  await page.locator('input[name="min_number_of_targets"]').fill('1');
  await page.locator('input[name="max_number_of_targets"]').click();
  await page.locator('input[name="max_number_of_targets"]').fill('2');
  await page.getByRole('button', { name: 'Initialiser les Heats' }).click();

  // delete false target
  await page.waitForTimeout(500);
  await page.getByRole('row', { name: dancer_array[0].first_name }).getByRole('button', { name: 'Delete' }).click();

  await page.getByRole('link', { name: 'Classement' }).click();
  await page.getByRole('row').nth(1).getByRole('link', { name: dancer_array[0].first_name }).click();
  await expect(page.getByText('Number of unique ranks')).toBeVisible();
  await page.getByRole('spinbutton').click();
  await page.getByRole('spinbutton').fill('1');
  await page.getByRole('button', { name: 'Mettre à jour les artefacts' }).click();
  await expect(page.getByRole('table').first()).toHaveText('Number of unique ranks1');
  await page.getByRole('link', { name: 'Classement' }).click();
  await page.getByRole('row').nth(1).getByRole('link', { name: dancer_array[1].first_name }).click();
  await expect(page.getByText('Number of unique ranks')).toBeVisible();
  await page.getByRole('spinbutton').click();
  await page.getByRole('spinbutton').fill('1');
  await page.getByRole('button', { name: 'Mettre à jour les artefacts' }).click();
  await expect(page.getByRole('table').first()).toHaveText('Number of unique ranks1');
  await page.getByRole('link', { name: 'Classement' }).click();

  await page.getByRole('link', { name: 'Competition', exact: true }).click();
  await page.getByRole('link', { name: 'Résultats/Promotions' }).click();
  await page.getByRole('button', { name: 'Calculer les promotions' }).click();
  await expect(page.getByRole('cell', { name: '1ème' })).toHaveCount(2);
  //await expect(page.getByRole('cell', { name: dancer_array[0].first_name })).toHaveCount(1);
  await expect(page.getByRole('cell', { name: dancer_array[1].first_name })).toHaveCount(1);
  await expect(page.getByRole('cell', { name: dancer_array[2].first_name })).toHaveCount(1);
  //await expect(page.getByRole('cell', { name: dancer_array[3].first_name })).toHaveCount(1);

});
