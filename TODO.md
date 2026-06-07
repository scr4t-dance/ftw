
Fixes for Spooky
================

* Bugfixes
  + heat generation (use circular buffer to handle any ratio between leaders and followers)
  + create all phases of a competition and assign judges/users/positions and permissions
  + check that ranking artefacts are a complete ranking for each judge

* Changes
  + Heat generation: put bigger heats in the middle (keep first heats lighter for judges, and keep last heats with free spots for fixes)


* Features
  + Select number of people in a heat, and heats thresholds at begining of comp
  + Thresholds and bonus:
    - Show thresholds (for next phase, but also points) in the ranking view
    - Show alerts if threshold ambiguous
    - Add form to give bonus points if threshod ambiguous
  + Page with all bibs of an event/comp and option to modify them, also search bib numbers
  + Alter heats in the UI
    - remove/move one dancer from a numbered heat into unallocated heat
    - add a dancer to a heat (search into unallocated, then previous phase by rank, etc...)
    - remove dancer from unallocated heat (with confirmation)
  + Save judges notes eagerly (for updating yes/alt/no counts and switching views)
  + User management
    - create user
    - change passwd
    - add/give/remove positions
