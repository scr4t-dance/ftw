#!/bin/bash

# for manual tests

echo "Creating event 4TWC..."
curl -s -X PUT http://localhost:8080/api/event -H "Content-Type: application/json" -d '{"name":"4 Temps Winter CUp","start_date":{"day":30,"month":1,"year":2025},"end_date":{"day":31,"month":1,"year":2025}}'
echo ""

echo "Creating event P4T..."
curl -s -X PUT http://localhost:8080/api/event -H "Content-Type: application/json" -d '{"name":"Printemps 4 Temps","start_date":{"day":6,"month":5,"year":2024},"end_date":{"day":9,"month":5,"year":2024}}'
echo ""

echo "Creating competition JJ for 4TWC"
curl -s -X PUT http://localhost:8080/api/comp "Content-Type: application/json" -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"], "n_leaders":5, n_follows:6}'
echo ""

echo "Creating prelims phase for 4TWC/JJ"
curl -s -X PUT localhost:8080/api/phase -H "Content-Type: application/json" -d '{"competition":2,"round":["Prelims"],"judge_artefact_descr":{"artefact":"yan","artefact_data":["overall"]},"head_judge_artefact_descr":{"artefact":"yan","artefact_data":["head"]}, "ranking_algorithm":{"algorithm":"Yan_weighted", "algorithm_data":{"weights":[{"yes":3,"alt":2,"no":1}], head_weights:[{"yes":3,"alt":2,"no":1}]}}}'
echo ""

echo "Creating finals phase for 4TWC/JJ"
curl -s -X PUT localhost:8080/api/phase -H "Content-Type: application/json" -d '{"competition":2,"round":["Finals"],"judge_artefact_descr":{"artefact":"ranking","artefact_data":null},"head_judge_artefact_descr":{"artefact":"ranking","artefact_data":null}, "ranking_algorithm":{"algorithm":"RPSS", "algorithm_data":null}}'
echo ""

echo "updating prelims for 4TWC/JJ"
curl -s -X PATCH localhost:8080/api/phase/2 -H "Content-Type: application/json" -d '{"competition":2,"round":["Finals"],"judge_artefact_descr":{"artefact":"yan","artefact_data":["technique"]},"head_judge_artefact_descr":{"artefact":"yan","artefact_data":["teamwork"]},  "ranking_algorithm":{"algorithm":"Yan_weighted", "algorithm_data":{"weights":[{"yes":4,"alt":2,"no":1}], head_weights:[{"yes":5,"alt":2,"no":1}]}}}'
echo ""

echo "getting prelims for 4TWC/JJ"
curl localhost:8080/api/phase/2 -H "Content-Type: application/json"
echo ""

# dancer
#curl -s -X PUT localhost:8080/api/dancer -H "Content-Type: application/json" -d '{"birthday":{"day":1,"month":1,"year":1900}, "last_name":"Bury", "first_name":"Guillaume", "email":"email@email.email", "as_leader":["Novice"], "as_follower":["Novice"]}'
#echo ""

#curl -s localhost:8080/api/dancer/1 -H "Content-Type: application/json"
#echo ""

#curl -s -X PATCH localhost:8080/api/dancer/1/as_leader -H "Content-Type: application/json" -d '["Intermediate"]'
#echo ""
