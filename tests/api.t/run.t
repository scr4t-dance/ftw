API Full Session Test
=====================

Initialization
--------------

Launch the FTW server in the background

  $ ftw --db=":memory:" -q --port=8081 > /dev/null &

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
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"],"n_leaders":0,"n_follows":0}'
  1

  $ curl -s -X PUT http://localhost:8081/api/comp \
  > -H "Content-Type: application/json" \
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"],"n_leaders":0,"n_follows":0}'
  2

Get the ids of competitions we created, and check their details

  $ curl -s http://localhost:8081/api/event/1/comps
  {"competitions":[1,2]}

  $ curl -s http://localhost:8081/api/comp/1
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"],"n_leaders":0,"n_follows":0}

  $ curl -s http://localhost:8081/api/comp/2
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"],"n_leaders":0,"n_follows":0}


Phase Management
----------------

Create some phase

  $ curl -s -X PUT localhost:8081/api/phase \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2,"round":["Prelims"],"judge_artefact_descr":{"artefact":"yan","artefact_data":["overall"]},"head_judge_artefact_descr":{"artefact":"yan","artefact_data":["head"]}, "ranking_algorithm":{"algorithm":"Yan_weighted", "weights":[{"yes":3,"alt":2,"no":1}], "head_weights":[{"yes":3,"alt":2,"no":1}]}}'
  1

  $ curl -s -X PUT localhost:8081/api/phase \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2,"round":["Finals"],"judge_artefact_descr":{"artefact":"ranking","artefact_data":null},"head_judge_artefact_descr":{"artefact":"ranking","artefact_data":null}, "ranking_algorithm":{"algorithm":"ranking", "algorithm_name":"RPSS"}}'
  2

Get the ids of phase we created, and check their details

  $ curl -s localhost:8081/api/comp/2/phases
  {"phases":[1,2]}

  $ curl -s localhost:8081/api/phase/1
  {"competition":2,"round":["Prelims"],"judge_artefact_descr":{"artefact":"yan","artefact_data":["overall"]},"head_judge_artefact_descr":{"artefact":"yan","artefact_data":["head"]},"ranking_algorithm":{"algorithm":"Yan_weighted","weights":[{"yes":3,"alt":2,"no":1}],"head_weights":[{"yes":3,"alt":2,"no":1}]}}

  $ curl -s localhost:8081/api/phase/2
  {"competition":2,"round":["Finals"],"judge_artefact_descr":{"artefact":"ranking","artefact_data":null},"head_judge_artefact_descr":{"artefact":"ranking","artefact_data":null},"ranking_algorithm":{"algorithm":"ranking","algorithm_name":"RPSS"}}

Update a phase

  $ curl -s -X PATCH localhost:8081/api/phase/2 \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2,"round":["Finals"],"judge_artefact_descr":{"artefact":"yan","artefact_data":["technique"]},"head_judge_artefact_descr":{"artefact":"yan","artefact_data":["teamwork"]},  "ranking_algorithm":{"algorithm":"Yan_weighted","weights":[{"yes":4,"alt":2,"no":1}], "head_weights":[{"yes":5,"alt":2,"no":1}]}}'
  null

  $ curl -s localhost:8081/api/phase/2
  {"competition":2,"round":["Finals"],"judge_artefact_descr":{"artefact":"yan","artefact_data":["technique"]},"head_judge_artefact_descr":{"artefact":"yan","artefact_data":["teamwork"]},"ranking_algorithm":{"algorithm":"Yan_weighted","weights":[{"yes":4,"alt":2,"no":1}],"head_weights":[{"yes":5,"alt":2,"no":1}]}}

  $ curl -s -X DELETE localhost:8081/api/phase/2 \
  > -H "Content-Type: application/json"
  2

  $ curl -s localhost:8081/api/phase/2
  {"message":"Phase not found"}


reset final phase for next tests
  $ curl -s -X PUT localhost:8081/api/phase \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2,"round":["Finals"],"judge_artefact_descr":{"artefact":"ranking","artefact_data":null},"head_judge_artefact_descr":{"artefact":"ranking","artefact_data":null}, "ranking_algorithm":{"algorithm":"ranking", "algorithm_name":"RPSS"}}'
  2

Dancer Management
-----------------

Create some dancers

  $ curl -s -X PUT http://localhost:8081/api/dancer \
  > -H "Content-Type: application/json" \
  > -d '{"birthday":{"day":1, "month":2, "year":2000}, "last_name":"Dancer", "first_name":"False", "email":"false.dancer@example.com", "as_leader":["None"], "as_follower":["None"]}'
  1

  $ curl -s -X PUT http://localhost:8081/api/dancer \
  > -H "Content-Type: application/json" \
  > -d '{"birthday":{"day":1, "month":2, "year":2001}, "last_name":"Dancer2", "first_name":"False2", "email":"false2.dancer2@example.com", "as_leader":["Novice"], "as_follower":["Intermediate"]}'
  2

  $ curl -s -X PUT http://localhost:8081/api/dancer \
  > -H "Content-Type: application/json" \
  > -d '{"birthday":{"day":1, "month":2, "year":2001}, "last_name":"No", "first_name":"Email", "as_leader":["Novice"], "as_follower":["Intermediate"]}'
  3

  $ curl -s -X PUT http://localhost:8081/api/dancer \
  > -H "Content-Type: application/json" \
  > -d '{"last_name":"No", "first_name":"birthday", "email":"false2.dancer2@example.com", "as_leader":["Novice"], "as_follower":["Intermediate"]}'
  4

Get the ids of dancers we created, and check their details

  $ curl -s http://localhost:8081/api/dancer/1
  {"birthday":{"day":1,"month":2,"year":2000},"last_name":"Dancer","first_name":"False","email":"false.dancer@example.com","as_leader":["None"],"as_follower":["None"]}

  $ curl -s http://localhost:8081/api/dancer/2
  {"birthday":{"day":1,"month":2,"year":2001},"last_name":"Dancer2","first_name":"False2","email":"false2.dancer2@example.com","as_leader":["Novice"],"as_follower":["Intermediate"]}

  $ curl -s http://localhost:8081/api/dancer/3
  {"birthday":{"day":1,"month":2,"year":2001},"last_name":"No","first_name":"Email","as_leader":["Novice"],"as_follower":["Intermediate"]}

  $ curl -s http://localhost:8081/api/dancer/4
  {"last_name":"No","first_name":"birthday","email":"false2.dancer2@example.com","as_leader":["Novice"],"as_follower":["Intermediate"]}

Bib management
--------------

create some bibs
  $ curl -s -X PUT localhost:8081/api/comp/2/bib \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2, "bib":201, "target":{"target_type":"single","target":2,"role":["Follower"]}}'
  {"dancers":[2]}

  $ curl -s -X PUT localhost:8081/api/comp/2/bib \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2, "bib":101, "target":{"target_type":"single","target":1,"role":["Leader"]}}'
  {"dancers":[1]}


  $ curl -s -X PUT localhost:8081/api/comp/2/bib \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2, "bib":102, "target":{"target_type":"single","target":3,"role":["Leader"]}}'
  {"dancers":[3]}

  $ curl -s -X PUT localhost:8081/api/comp/2/bib \
  > -H "Content-Type: application/json" \
  > -d '{"competition":2, "bib":204, "target":{"target_type":"single","target":4,"role":["Follower"]}}'
  {"dancers":[4]}

get bibs

  $ curl -s localhost:8081/api/comp/2/bibs
  {"bibs":[{"competition":2,"bib":101,"target":{"target_type":"single","target":1,"role":["Leader"]}},{"competition":2,"bib":102,"target":{"target_type":"single","target":3,"role":["Leader"]}},{"competition":2,"bib":201,"target":{"target_type":"single","target":2,"role":["Follower"]}},{"competition":2,"bib":204,"target":{"target_type":"single","target":4,"role":["Follower"]}}]}

  $ curl -s localhost:8081/api/comp/2/bibs
  {"bibs":[{"competition":2,"bib":101,"target":{"target_type":"single","target":1,"role":["Leader"]}},{"competition":2,"bib":102,"target":{"target_type":"single","target":3,"role":["Leader"]}},{"competition":2,"bib":201,"target":{"target_type":"single","target":2,"role":["Follower"]}},{"competition":2,"bib":204,"target":{"target_type":"single","target":4,"role":["Follower"]}}]}

  $ curl -s localhost:8081/api/dancer/2/competition_history
  {"competitions":[2]}


Judging management
------------------

add panel with no head

  $ curl -s -X PUT localhost:8081/api/phase/1/judges \
  > -H "Content-Type: application/json" \
  > -d '{"panel_type": "single", "leaders": {"dancers":[1]}, "followers" : {"dancers":[2]}, "head":null}'
  1

  $ curl -s localhost:8081/api/phase/1/judges
  {"panel_type":"single","panel_type":"single","leaders":{"dancers":[1]},"followers":{"dancers":[2]},"head":null}

  $ curl -s -X PUT localhost:8081/api/phase/2/judges \
  > -H "Content-Type: application/json" \
  > -d '{"panel_type": "couple", "couples": {"dancers":[1,2]}, "head":null}'
  2


Heats management
----------------

init heats with bib from competition

  $ curl -s -X POST localhost:8081/api/phase/1/init_heats_with_bibs
  1

get heats
  $ curl -s localhost:8081/api/phase/1/heats
  {"heat_type":"single","heat_type":"single","heats":[{"followers":[{"target_type":"single","target":4,"role":["Follower"]},{"target_type":"single","target":2,"role":["Follower"]}],"leaders":[{"target_type":"single","target":3,"role":["Leader"]},{"target_type":"single","target":1,"role":["Leader"]}]}]}

move target to new heat

  $ curl -s -X DELETE localhost:8081/api/phase/1/heat_target \
  > -H "Content-Type: application/json" \
  > -d '{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":3,"role":["Leader"]},"judge":0,"description":{"artefact":"yan","artefact_data":["overall"]}}'
  1


  $ curl -s -X PUT localhost:8081/api/phase/1/heat_target \
  > -H "Content-Type: application/json" \
  > -d '{"phase_id":1,"heat_number":3,"target":{"target_type":"single","target":3,"role":["Leader"]},"judge":0,"description":{"artefact":"yan","artefact_data":["overall"]}}'
  5


  $ curl -s localhost:8081/api/phase/1/heats
  {"heat_type":"single","heat_type":"single","heats":[{"followers":[{"target_type":"single","target":4,"role":["Follower"]},{"target_type":"single","target":2,"role":["Follower"]}],"leaders":[{"target_type":"single","target":1,"role":["Leader"]}]},{"followers":[],"leaders":[]},{"followers":[],"leaders":[]},{"followers":[],"leaders":[{"target_type":"single","target":3,"role":["Leader"]}]}]}

randomize heats
  $ curl -s -X PUT localhost:8081/api/phase/1/randomize_heats \
  > -H "Content-Type: application/json" \
  > -d '{"min_number_of_targets":1, "max_number_of_targets":1,"late_heat_range":1,"late_heat_ids":"3","early_heat_range":1,"early_heat_ids":"2"}'
  1

get randomized heats
  $ curl -s localhost:8081/api/phase/1/heats
  {"heat_type":"single","heat_type":"single","heats":[{"followers":[],"leaders":[]},{"followers":[{"target_type":"single","target":2,"role":["Follower"]}],"leaders":[{"target_type":"single","target":1,"role":["Leader"]}]},{"followers":[{"target_type":"single","target":4,"role":["Follower"]}],"leaders":[{"target_type":"single","target":3,"role":["Leader"]}]}]}

Artefacts
---------

Get empty artefacts

  $ curl -s localhost:8081/api/phase/1/artefact/judge/1
  {"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":1,"role":["Leader"]},"judge":1,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":null},{"heat_target_judge":{"phase_id":1,"heat_number":2,"target":{"target_type":"single","target":3,"role":["Leader"]},"judge":1,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":null}]}

  $ curl -s localhost:8081/api/phase/1/artefact/judge/2
  {"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":2,"role":["Follower"]},"judge":2,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":null},{"heat_target_judge":{"phase_id":1,"heat_number":2,"target":{"target_type":"single","target":4,"role":["Follower"]},"judge":2,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":null}]}

set artefact

  $ curl -s localhost:8081/api/phase/1
  {"competition":2,"round":["Prelims"],"judge_artefact_descr":{"artefact":"yan","artefact_data":["overall"]},"head_judge_artefact_descr":{"artefact":"yan","artefact_data":["head"]},"ranking_algorithm":{"algorithm":"Yan_weighted","weights":[{"yes":3,"alt":2,"no":1}],"head_weights":[{"yes":3,"alt":2,"no":1}]}}

  $ curl -s -X PUT localhost:8081/api/phase/1/artefact/judge/1 \
  > -H "Content-Type: application/json" \
  > -d '{"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":1,"role":["Leader"]},"judge":1,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type": "yan","artefact_data": [["No"]]}},{"heat_target_judge":{"phase_id":1,"heat_number":2,"target":{"target_type":"single","target":3,"role":["Leader"]},"judge":1,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type": "yan","artefact_data": [["Yes"]]}}]}'
  {"dancers":[1,1]}

  $ curl -s localhost:8081/api/phase/1/artefact/judge/1
  {"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":1,"role":["Leader"]},"judge":1,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type":"yan","artefact_data":[["No"]]}},{"heat_target_judge":{"phase_id":1,"heat_number":2,"target":{"target_type":"single","target":3,"role":["Leader"]},"judge":1,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type":"yan","artefact_data":[["Yes"]]}}]}



Promote dancers to next phase
-----------------------------

set temporary artefact

  $ curl -s -X PUT localhost:8081/api/phase/1/artefact/judge/2 \
  > -H "Content-Type: application/json" \
  > -d '{"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":2,"role":["Follower"]},"judge":2,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type": "yan","artefact_data": [["No"]]}}]}'
  {"dancers":[2]}



add artefact for complete data
  $ curl -s -X PUT localhost:8081/api/phase/1/artefact/judge/2 \
  > -H "Content-Type: application/json" \
  > -d '{"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":2,"role":["Follower"]},"judge":2,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type": "yan","artefact_data": [["Yes"]]}}]}'
  {"dancers":[2]}

  $ curl -s -X PUT localhost:8081/api/phase/1/artefact/judge/2 \
  > -H "Content-Type: application/json" \
  > -d '{"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":2,"target":{"target_type":"single","target":4,"role":["Follower"]},"judge":2,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type": "yan","artefact_data": [["Alt"]]}}]}'
  {"dancers":[2]}


  $ curl -s localhost:8081/api/phase/1/artefact/judge/2
  {"artefacts":[{"heat_target_judge":{"phase_id":1,"heat_number":1,"target":{"target_type":"single","target":2,"role":["Follower"]},"judge":2,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type":"yan","artefact_data":[["Yes"]]}},{"heat_target_judge":{"phase_id":1,"heat_number":2,"target":{"target_type":"single","target":4,"role":["Follower"]},"judge":2,"description":{"artefact":"yan","artefact_data":["overall"]}},"artefact":{"artefact_type":"yan","artefact_data":[["Alt"]]}}]}

get rankings

  $ curl -s localhost:8081/api/phase/1/ranking
  {"target_type":"single","target_type":"single","leaders":{"ranks":[{"ranking_type":"yan","ranking_type":"yan","target":{"target_type":"single","target":3,"role":["Leader"]},"rank":1,"score":3.0},{"ranking_type":"yan","ranking_type":"yan","target":{"target_type":"single","target":1,"role":["Leader"]},"rank":2,"score":1.0}]},"followers":{"ranks":[{"ranking_type":"yan","ranking_type":"yan","target":{"target_type":"single","target":2,"role":["Follower"]},"rank":1,"score":3.0},{"ranking_type":"yan","ranking_type":"yan","target":{"target_type":"single","target":4,"role":["Follower"]},"rank":2,"score":2.0}]}}

promote to next phase

  $ curl -s -X PUT localhost:8081/api/phase/1/promote \
  > -H "Content-Type: application/json" \
  > -d '{"number_of_targets_to_promote":1}'
  2

  $ curl -s localhost:8081/api/phase/2/singles_heats
  {"heat_type":"single","heat_type":"single","heats":[{"followers":[{"target_type":"single","target":2,"role":["Follower"]}],"leaders":[{"target_type":"single","target":3,"role":["Leader"]}]}]}

  $ curl -s localhost:8081/api/phase/2/heats
  {"heat_type":"couple","heat_type":"couple","heats":[{"couples":[]}]}

  $ curl -s -X PUT localhost:8081/api/phase/2/convert_to_couple \
  > -H "Content-Type: application/json" \
  > -d '{"heat_number":0}'
  2

  $ curl -s localhost:8081/api/phase/2/heats
  {"heat_type":"couple","heat_type":"couple","heats":[{"couples":[{"target_type":"couple","leader":3,"follower":2}]}]}

move to next heat

 # $ curl -s -X PUT localhost:8081/api/phase/2/heat_target \
 # > -H "Content-Type: application/json" \
 # > -d '{"phase_id":2,"heat_number":1,"target":{"target_type":"couple","leader":3,"follower":2},"judge":0,"description":{"artefact":"yan","artefact_data":["overall"]}}'
 # 5

  $ curl -s localhost:8081/api/phase/2/heats
  {"heat_type":"couple","heat_type":"couple","heats":[{"couples":[{"target_type":"couple","leader":3,"follower":2}]}]}


  $ curl -s -X PUT localhost:8081/api/phase/2/randomize_heats \
  > -H "Content-Type: application/json" \
  > -d '{"min_number_of_targets":1, "max_number_of_targets":1,"late_heat_range":1,"late_heat_ids":"","early_heat_range":1,"early_heat_ids":""}'
  2


  $ curl -s localhost:8081/api/phase/2/heats
  {"heat_type":"couple","heat_type":"couple","heats":[{"couples":[]},{"couples":[{"target_type":"couple","leader":3,"follower":2}]}]}


Promotion
---------

add finals artefacts

  $ curl -s -X PUT localhost:8081/api/phase/2/artefact/judge/1 \
  > -H "Content-Type: application/json" \
  > -d '{"artefacts":[{"heat_target_judge":{"phase_id":2,"heat_number":1,"target":{"target_type":"couple","leader":3,"follower":2},"judge":1,"description":{"artefact":"ranking","artefact_data":null}},"artefact":{"artefact_type": "ranking","artefact_data": 1}}]}'
  {"dancers":[1]}


  $ curl -s -X PUT localhost:8081/api/phase/2/artefact/judge/2 \
  > -H "Content-Type: application/json" \
  > -d '{"artefacts":[{"heat_target_judge":{"phase_id":2,"heat_number":1,"target":{"target_type":"couple","leader":3,"follower":2},"judge":2,"description":{"artefact":"ranking","artefact_data":null}},"artefact":{"artefact_type": "ranking","artefact_data": 1}}]}'
  {"dancers":[2]}

get rankings

  $ curl -s localhost:8081/api/phase/2/ranking
  {"target_type":"couple","target_type":"couple","couples":{"ranks":[{"ranking_type":"rpss","ranking_type":"rpss","target":{"target_type":"couple","leader":3,"follower":2},"rank":1,"ranking_details":["--"]}]}}


Promote
-------

#  $ curl -s localhost:8081/api/comp/2/results
#   {"results":[]}
#
#   $ curl -s -X PUT localhost:8081/api/comp/2/promotions
#   {"dancers":[1,2,3,4]}
#
#   $ curl -s localhost:8081/api/comp/2/promotions
#   {"promotions":[{"competition":2,"dancer":1,"role":["Leader"],"current_divisions":["None"],"new_divisions":["Novice"],"reason":"Participation"},{"competition":2,"dancer":2,"role":["Follower"],"current_divisions":["None"],"new_divisions":["Intermediate"],"reason":"Participation"},{"competition":2,"dancer":3,"role":["Leader"],"current_divisions":["None"],"new_divisions":["Intermediate"],"reason":"Participation"},{"competition":2,"dancer":4,"role":["Follower"],"current_divisions":["None"],"new_divisions":["Novice"],"reason":"Participation"}]}
#
#
#
#   $ curl -s localhost:8081/api/comp/2/results
#   {"results":[{"competition":2,"dancer":1,"role":["Leader"],"result":{"prelims":{"present":true,"result_type":"present"},"octofinals":{"present":false,"result_type":"not_present"},"quarterfinals":{"present":false,"result_type":"not_present"},"semifinals":{"present":false,"result_type":"not_present"},"finals":{"present":false,"result_type":"not_present"}},"points":0},{"competition":2,"dancer":2,"role":["Follower"],"result":{"prelims":{"present":true,"result_type":"present"},"octofinals":{"present":false,"result_type":"not_present"},"quarterfinals":{"present":false,"result_type":"not_present"},"semifinals":{"present":false,"result_type":"not_present"},"finals":{"ranked":1,"result_type":"ranked"}},"points":7},{"competition":2,"dancer":3,"role":["Leader"],"result":{"prelims":{"present":true,"result_type":"present"},"octofinals":{"present":false,"result_type":"not_present"},"quarterfinals":{"present":false,"result_type":"not_present"},"semifinals":{"present":false,"result_type":"not_present"},"finals":{"ranked":1,"result_type":"ranked"}},"points":7},{"competition":2,"dancer":4,"role":["Follower"],"result":{"prelims":{"present":true,"result_type":"present"},"octofinals":{"present":false,"result_type":"not_present"},"quarterfinals":{"present":false,"result_type":"not_present"},"semifinals":{"present":false,"result_type":"not_present"},"finals":{"present":false,"result_type":"not_present"}},"points":0}]}


End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"
