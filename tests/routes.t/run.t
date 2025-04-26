API Full Session Test
=====================

Initialization
--------------

Launch the FTW server in the background
  $ ftw --db="test.db" --port=8083 > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

Get default route

  $ curl -s -o /dev/null -w '%{http_code}\n' localhost:8083/index.html
  200

End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"
  [1]
