Launch the FTW server in the background

  $ ftw --db=":memory" &> /dev/null &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

API PUT: create an event

  $ curl -s -X PUT localhost:8080/api/event \
  > -H "Content-Type: application/json" \
  > -d '{"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}'
  1

API GET: list all events

  $ curl -s localhost:8080/api/events
  {"events":[1]}

API GET: query an event data

  $ curl -s localhost:8080/api/event/1
  {"name":"P4T","start_date":{"day":1,"month":1,"year":2025},"end_date":{"day":3,"month":1,"year":2025}}

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ kill $(jobs -p)

