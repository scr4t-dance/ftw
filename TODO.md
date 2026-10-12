
Fixes for Spooky
================

* Changes
  + Heat generation: put bigger heats in the middle (keep first heats lighter for judges, and keep last heats with free spots for fixes)

* Features
  + Add a strip functionality to extract only the divs of a full DB
  + Finish full DB import to have a full scr4t DB (almost)
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
    - add/give/remove positions


Others
======

* Features
  + Add position for SCR4T social media manager (read access to results of comps, but no write access)


