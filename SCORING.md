Documentation pour réaliser le scoring d'une compétition
========================================================

Notes pour la Paris Plage 2025

Préparation de l'événement
--------------------------

# Initialiser la base de données

Nécessaire pour avoir les informations détaillées sur les `Divisions`s des danceurs.

Cloner l'archive des compétitions dans un dossier à côté du projet scrat
```bash
git clone https://github.com/scr4t-dance/acorn.git
```

Depuis le dépôt ftw, exécuter la commande suivante.
```bash
rm tests/test.db && dune exec -- ftw import --db=tests/test.db ../acorn/archive &> import.logs
```
**TODO, la commande renvoie une erreur `Import failed due to exception: Failure("dancer id not in db: 1")`**.
**trouver une manière d'initialiser la liste des danseurs**

Il existe deux formats de fichiers
* `ftw.1` c'est pour les trucs que tu fais à la main (et/ou les vieilles compétitions, avec des tsv à parser)
* `ftw.2` c'est le nouveau format qui est exporté (et donc ou tout est en toml)

Le projet `acorn` ne contient que des données au format `ftw.2`.

# Importer la liste des participants

Initialiser un fichier toml dans le répertoire acorn associé à l'événement à organiser.
Squelette minimal ci-dessous. Préférez le format `ftw.1` pour faciliter la génération manuelle du fichier.

```toml
# FTW Event Info
[config]
format = "ftw.1"

[event]
name = "Rock 4 Temps Paris Plage Cup 2025"
short = "Paris Plage 2025"
start_date = 2025-12-06
end_date = 2025-12-06

[event.comps.jj_adv]
name = "JnJ Advanced"
kind = "Jack_and_Jill"
category = "Advanced"
check_divs = false
leaders = 5
follows = 5
results="""
"""

[event.comps.jj_inter]
name = "JnJ Inter"
kind = "Jack_and_Jill"
category = "Intermediate"
check_divs = false
leaders = 15
follows = 15
results="""
"""

[event.comps.jj_initie]
name = "JnJ Initié"
kind = "Jack_and_Jill"
category = "Novice"
leaders = 31
follows = 34
results="""
"""

[event.comps.jj_initie.dancers]
bibs="""

"""

[event.comps.jj_inter.dancers]
bibs="""

"""

[event.comps.jj_adv.dancers]
bibs="""

"""
```

Copier-coller dans chaque partie `bibs` les nom, prénom, dossard leader, dossard follower des participants à
cette division.
Il faut que chaque colonne soit séparée par des tabulations. Le dossard doit être préfixé d'un croisillon.
Laisser vide si le compétiteurice ne participe pas à la compétition dans la division indiquée.
Exemple :
```tsv
Doe	Jane	# 100	# 200
```

Importer les participants avec la ligne de commande suivante (identique à celle utilisée plus haut)
```bash
rm tests/test.db && dune exec -- ftw import --db=tests/test.db ../acorn/archive &> import.logs
```

Lisez le fichier `import.logs`.
* Vérifiez les corrections orthographiques (pointent-elles vers la bonne personne)
* Identifiez s'il y a eu des nom-prénom non reconnus, qui ont créé de nouveaux participants dans la BDD.

Démarrer le serveur
```bash
make run
```

Vérifier que votre événement a correctement été créé.
Allez sur la page `admin/events/:id_event/bibs` pour consulter les dossards associés à l'événement.
Vérifiez que les dossards ont bien été importé dans toutes les compétitions.
Chaque ligne est correspond à une personne et un rôle unique.
Il doit y avoir un seul dossard renseigné par ligne (sinon cela signifie qu'il y a une personne
qui s'est inscrite simultanément dans deux divisions avec le même rôle.
ce qui est interdit par le règlement SCRAT).



# Configurer les phases

Une fois les participants importés, il faut configurer le nombre de phase en fonction du nombre de participants pour chaque compétition.
Voir [le règlement SCRAT](https://4temps.dance/rules) pour savoir s'il faut des prelim, semi, etc...

Dans chaque phase
* Renseigner les juges de la compétition
* Renseigner les critères de jugement

# Impressions

* Imprimer la liste des dossards de l'événement en 3 exemplaires : 2 pour les personnes à l'accueil,
1 en bonus

# Génération des poules

* S'assurer d'avoir récupéré la liste des paires interdites
* Identifier les personnes qui doivent arriver de préférence dans les premières poules,
  et celles qui doivent arriver de préférence dans les dernières poules.
  Généralement, ce seront des juges qui enchaine avec une compétition, ou des personnes du staff.


Pendant l'événement
-------------------

Durant l'accueil, mettre à jour la liste des inscriptions et dossards en fonction des modifications de dernière minute.
Noter les personnes pour lesquelles le dossard a été récupéré en avance à cause de problèmes de transport,
placez les de préférence dans les dernières poules.

Pour les prélims,
* cliquez sur le bouton "Initialiser les Heats avec les dossards",
* remplissez ensuite les informations sur le nombre min et max de target par poule,
les targets devant passer plus tard.
* Cliquer sur le bouton "Initialiser les Heats" pour procéder à la répartition aléatoire dans les différentes poules.
