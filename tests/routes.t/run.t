API Full Session Test
=====================

Initialization
--------------

Launch the FTW server in the background
  $ ftw --db=":memory:" --port=8082 > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

Get default route

  $ curl -s localhost:8082/index.html | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/logo192.png"/><link rel="manifest" href="/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/js/main.8bb6bb30.js"></script><link href="/static/css/main.6099b47f.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>

End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"
