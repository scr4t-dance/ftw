API Full Session Test
=====================

Initialization
--------------

Launch the FTW server in the background

  $ ftw --db=":memory" > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1


Event Management
----------------

Create a first event

  $ curl -s -X PUT localhost:8080/api/event \
  > -H "Content-Type: application/json" \
  > -d '{"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}'
  1

List all events

  $ curl -s localhost:8080/api/events
  {"events":[1]}

Check the details of the create event

  $ curl -s localhost:8080/api/event/1
  {"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}


Competition Management
----------------------

Create some competitions

  $ curl -s -X PUT localhost:8080/api/comp \
  > -H "Content-Type: application/json" \
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"]}'

  $ curl -s -X PUT localhost:8080/api/comp \
  > -H "Content-Type: application/json" \
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"]}'

Get the ids of competitions we created, and check their details

  $ curl -s localhost:8080/api/event/1/comps
  {"comps":[1,2]}

  $ curl -s localhost:8080/api/comp/1
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"]}

  $ curl -s localhost:8080/api/comp/2
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"]}


Phase Management
----------------

Create some phase

  $ curl -s -X PUT localhost:8080/api/phase \
  > -H "Content-Type: application/json" \
  > -d '{"name":"p","competition":2,"round":"Prelim","judge_artefact":"","head_judge_artefact":"","ranking_algorithm":""}'
  1

  $ curl -s -X PUT localhost:8080/api/phase \
  > -H "Content-Type: application/json" \
  > -d '{"name":"q","competition":2,"round":"Finals","judge_artefact":"","head_judge_artefact":"","ranking_algorithm":""}'
  2

Get the ids of phase we created, and check their details

  $ curl -s localhost:8080/api/comp/2/phases
  {"phases":[1,2]}

  $ curl -s localhost:8080/api/phase/1
  {"name":"p","competition":2,"round":"Prelim","judge_artefact":"","head_judge_artefact":"","ranking_algorithm":""}

  $ curl -s localhost:8080/api/phase/2
  {"name":"q","competition":2,"round":"Finals","judge_artefact":"","head_judge_artefact":"","ranking_algorithm":""}

Miscellanous data
-----------------

  $ curl -s localhost:8080/api/kinds
  {"kinds":[["Routine"],["Strictly"],["JJ_Strictly"],["Jack_and_Jill"]]}

  $ curl -s localhost:8080/api/categories
  {"categories":[["Novice"],["Intermediate"],["Advanced"],["Regular"],["Qualifying"],["Invited"]]}

  $ curl -s localhost:8080/api/divisions
  {"divisions":[["Novice"],["Intermediate"],["Advanced"]]}

End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"

