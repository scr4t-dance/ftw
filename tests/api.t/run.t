Launch the FTW server in the background

  $ ftw --db=":memory" &> /dev/null & sleep 1

API PUT: /api/event

  $ curl -s -X PUT localhost:8080/api/event \
  > -H "Content-Type: application/json" \
  > -d '{"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}'
  1

API GET: /api/events

  $ curl -s localhost:8080/api/events
  {"events":[1]}

API GET: /event/:id

  $ curl -s localhost:8080/api/event/1
  {"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ kill $(jobs -p)

