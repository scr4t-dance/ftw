API Full Session Test
=====================

Initialization
--------------

test path
  $ ls ../../src/backend/static
  asset-manifest.json
  favicon.ico
  index.html
  logo - Copie.png:Zone.Identifier
  logo.png
  logo.png:Zone.Identifier
  logo192.png
  logo512.png
  manifest.json
  robots.txt
  static
  $ ls ../../src/backend/static/static
  css
  js
  media
  $ cat ../../src/backend/static/index.html
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>


Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

Launch the FTW server in the background
  $ ftw --db=":memory:" --port=8082 > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

Get default routes

  $ curl -IL localhost:8082/
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
  $ curl -s localhost:8082/index.html | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
  $ curl -s localhost:8082/event | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
  $ curl -s localhost:8082/competition | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
  $ curl -s localhost:8082/dancer | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
  $ curl -s localhost:8082/rules | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
  $ curl -s localhost:8082/faq | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
  $ curl -s localhost:8082/about | head -1
  <!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" type="image/png" href="/static/logo.png"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/static/logo192.png"/><link rel="manifest" href="/static/manifest.json"/><title>SCR4T</title><script defer="defer" src="/static/static/js/main.b40d76b9.js"></script><link href="/static/static/css/main.21041af4.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>

End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"
