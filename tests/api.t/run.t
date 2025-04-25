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
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"],"leaders_count":0,"followers_count":0}'
  1

  $ curl -s -X PUT http://localhost:8081/api/comp \
  > -H "Content-Type: application/json" \
  > -d '{"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"],"leaders_count":0,"followers_count":0}'
  2

Get the ids of competitions we created, and check their details

  $ curl -s http://localhost:8081/api/event/1/comps
  {"competitions":[1,2]}

  $ curl -s http://localhost:8081/api/comp/1
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Novice"],"leaders_count":0,"followers_count":0}

  $ curl -s http://localhost:8081/api/comp/2
  {"event":1,"name":"","kind":["Jack_and_Jill"],"category":["Intermediate"],"leaders_count":0,"followers_count":0}

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

Get the ids of competitions we created, and check their details

  $ curl -s http://localhost:8081/api/dancer/1
  {"birthday":{"day":1,"month":2,"year":2000},"last_name":"Dancer","first_name":"False","email":"false.dancer@example.com","as_leader":["None"],"as_follower":["None"]}

  $ curl -s http://localhost:8081/api/dancer/2
  {"birthday":{"day":1,"month":2,"year":2001},"last_name":"Dancer2","first_name":"False2","email":"false2.dancer2@example.com","as_leader":["Novice"],"as_follower":["Intermediate"]}

End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"
