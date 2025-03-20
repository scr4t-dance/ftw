# for manual tests

curl -s -X PUT http://localhost:8080/api/event -H "Content-Type: application/json" -d '{"name":"4 Temps Winter CUp","start_date":{"day":30,"month":1,"year":2025},"end_date":{"day":31,"month":1,"year":2025}}'

curl -s -X PUT http://localhost:8080/api/event -H "Content-Type: application/json" -d '{"name":"Printemps 4 Temps","start_date":{"day":6,"month":5,"year":2024},"end_date":{"day":9,"month":5,"year":2024}}'

curl -s -X PUT localhost:8080/api/phase -H "Content-Type: application/json" -d '{"competition":1,"round":["Prelims"],"judge_artefact_description":"bonus","head_judge_artefact_description":"bonus","ranking_algorithm":"RPSS"}'

curl -s -X PUT localhost:8080/api/dancer -H "Content-Type: application/json" -d '{"birthday":{"day":1,"month":1,"year":1900}, "last_name":"Bury", "first_name":"Guillaume", "email":"email@email.email", "as_leader":["Novice"], "as_follower":["Novice"]}'

curl -s localhost:8080/api/dancer/1 -H "Content-Type: application/json"


curl -s -X PATCH localhost:8080/api/dancer/1/as_leader -H "Content-Type: application/json" -d '["Intermediate"]'