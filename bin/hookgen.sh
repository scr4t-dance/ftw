#!/bin/bash

# Start the backend server
dune exec -- ftw --db=":memory:" --port=8083> bin/hookgen-ftw.log 2>&1 &
FTW_PID=$!
echo $FTW_PID > src/hookgen/ftw.pid

# Ensure the backend server is cleaned up on exit
cleanup() {
    if [[ -f src/hookgen/ftw.pid ]]; then
        kill -TERM $(cat src/hookgen/ftw.pid) 2>/dev/null
        echo "Stopped backend server"
        rm -f src/hookgen/ftw.pid
    fi
}
trap cleanup INT TERM EXIT

sleep 1
cd src/hookgen

echo "downloading raw_openapi.json"
curl -s http://localhost:8083/openapi.json -o raw_openapi.json.tmp

if test -r raw_openapi.json;
then
    if ! cmp -s raw_openapi.json.tmp raw_openapi.json; then
        mv -f raw_openapi.json.tmp raw_openapi.json
        echo "OpenApi specification was updated. Please run 'make backend' again"
    fi
else
    mv raw_openapi.json.tmp raw_openapi.json
    echo "OpenApi specification was updated. Please run 'make backend' again"
fi

echo "kiling backend server"
cd ../..
cleanup

echo "successfully generated hooks"
