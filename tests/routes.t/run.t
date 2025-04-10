API Full Session Test
=====================

Initialization
--------------

Launch the FTW server in the background
  $ ftw --db=":memory:" --port=8082 > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

Get default routes

  $ curl -IL localhost:8082/
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                   Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  HTTP/1.1 404 Not Found
  Set-Cookie: dream.session=0TV2_n9jxtH7Pl9C9AtqZ0VJE; Max-Age=1209599; Path=/; HttpOnly; SameSite=Lax
  Access-Control-Allow-Origin: *
  Access-Control-Allow-Headers: Content-Type, Authorization
  Content-Length: 0
  
  $ curl -s localhost:8082/index.html | head -1

End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"
