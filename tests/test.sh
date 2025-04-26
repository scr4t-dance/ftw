


curl -s -X PUT http://localhost:8081/api/dancer -H "Content-Type: application/json" -d '{"birthday":{"day":1, "month":2, "year":2001}, "last_name":"No", "first_name":"Email", "as_leader":["Novice"], "as_follower":["Intermediate"]}'


curl -s -X PUT http://localhost:8081/api/dancer -H "Content-Type: application/json" -d '{"last_name":"No", "first_name":"birthday", "email":"false2.dancer2@example.com", "as_leader":["Novice"], "as_follower":["Intermediate"]}'
