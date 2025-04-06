#!/bin/bash

# Start the backend server
dune exec -- ftw --db=":memory:" --port=8083> ftw.log 2>&1 &
FTW_PID=$!
echo $FTW_PID > ftw.pid

# Ensure the backend server is cleaned up on exit
cleanup() {
    if [[ -f ftw.pid ]]; then
        kill -TERM $(cat ftw.pid) 2>/dev/null
        echo "Stopped backend server"
        rm -f ftw.pid
    fi
}
trap cleanup INT TERM EXIT

sleep 1
cd src/hookgen

echo "downloading raw_openapi.json"
curl -s http://localhost:8083/openapi.json -o raw_openapi.json

echo "pretty printing openapi.json"
node pretty_print_openapi_json.js

echo "generating configuration"
./node_modules/.bin/orval --config ./orval.config.js

echo "kiling backend server"
cd ../..
cleanup

echo "successfully generated hooks"
