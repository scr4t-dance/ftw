API Full Session Test
=====================

Initialization
--------------

Launch the FTW server in the background

  $ ftw --db=":memory" > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

Get default routes
  $ curl -Is localhost:8080/ | head -1
  HTTP/1.1 404 Not Found
  $ curl -Is localhost:8080/index.html | head -1
  HTTP/1.1 404 Not Found
  $ curl -Is localhost:8080/event.html | head -1
  HTTP/1.1 404 Not Found
  $ curl -Is localhost:8080/competition.html | head -1
  HTTP/1.1 404 Not Found
  $ curl -Is localhost:8080/dancer.html | head -1
  HTTP/1.1 404 Not Found
  $ curl -Is localhost:8080/rules.html | head -1
  HTTP/1.1 404 Not Found
  $ curl -Is localhost:8080/faq.html | head -1
  HTTP/1.1 404 Not Found
  $ curl -Is localhost:8080/about.html | head -1
  HTTP/1.1 404 Not Found


End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"

