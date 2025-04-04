API Full Session Test
=====================

Initialization
--------------

Launch the FTW server in the background

  $ ftw --db=":memory:" --port=8081 > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1


Event Management
----------------

Create a first event

  $ curl -s -X PUT http://localhost:8081/api/event \
  > -H "Content-Type: application/json" \
  > -d '{"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}'
  1

List all events

  $ curl -s http://localhost:8081/api/events
  {"events":[1]}

Check the details of the create event

  $ curl -s http://localhost:8081/api/event/1
  {"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}


Competition Management
----------------------

Create some competitions

  $ curl -s -X PUT http://localhost:8081/api/comp \
  > -H "Content-Type: application/json" \
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"]}'
  1

  $ curl -s -X PUT http://localhost:8081/api/comp \
  > -H "Content-Type: application/json" \
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"]}'
  2

Get the ids of competitions we created, and check their details

  $ curl -s http://localhost:8081/api/event/1/comps
  {"comps":[1,2]}

  $ curl -s http://localhost:8081/api/comp/1
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"]}

  $ curl -s http://localhost:8081/api/comp/2
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"]}


Phase Management
----------------

Create some phase

  $ curl -s -X PUT localhost:8081/api/phase \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2,"round":["Prelims"],"judge_artefact_description":{"artefact":"yan","yan_criterion":[["overall",{"yes":3,"alt":2,"no":1}]],"algorithm_for_ranking":null},"head_judge_artefact_description":{"artefact":"yan","yan_criterion":[["head",{"yes":3,"alt":2,"no":1}]],"algorithm_for_ranking":null}}'
  1

  $ curl -s -X PUT localhost:8081/api/phase \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2,"round":["Finals"],"judge_artefact_description":{"artefact":"ranking","yan_criterion":null,"algorithm_for_ranking":"RPSS"},"head_judge_artefact_description":{"artefact":"ranking","yan_criterion":null,"algorithm_for_ranking":"RPSS"}}'
  2

Get the ids of phase we created, and check their details

  $ curl -s localhost:8081/api/comp/2/phases
  {"phases":[1,2]}

  $ curl -s localhost:8081/api/phase/1
  {"competition":2,"round":["Prelims"],"judge_artefact_description":{"artefact":"yan","yan_criterion":[["overall",{"yes":3,"alt":2,"no":1}]],"algorithm_for_ranking":null},"head_judge_artefact_description":{"artefact":"yan","yan_criterion":[["head",{"yes":3,"alt":2,"no":1}]],"algorithm_for_ranking":null}}

  $ curl -s localhost:8081/api/phase/2
  {"competition":2,"round":["Finals"],"judge_artefact_description":{"artefact":"ranking","yan_criterion":null,"algorithm_for_ranking":"RPSS"},"head_judge_artefact_description":{"artefact":"ranking","yan_criterion":null,"algorithm_for_ranking":"RPSS"}}

Update a phase

  $ curl -s -X PATCH localhost:8081/api/phase/2 \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2,"round":["Finals"],"judge_artefact_description":{"artefact":"yan","yan_criterion":[["technique",{"yes":4,"alt":2,"no":1}]],"algorithm_for_ranking":null},"head_judge_artefact_description":{"artefact":"yan","yan_criterion":[["teamwork",{"yes":5,"alt":2,"no":1}]],"algorithm_for_ranking":null}}'
  2

  $ curl -s localhost:8081/api/phase/2
  {"competition":2,"round":["Finals"],"judge_artefact_description":{"artefact":"yan","yan_criterion":[["technique",{"yes":4,"alt":2,"no":1}]],"algorithm_for_ranking":null},"head_judge_artefact_description":{"artefact":"yan","yan_criterion":[["teamwork",{"yes":4,"alt":2,"no":1}]],"algorithm_for_ranking":null}}

  $ curl -s -X DELETE localhost:8081/api/phase/2 \
  > -H "Content-Type: application/json"
  2

  $ curl -s localhost:8081/api/phase/2


End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"

