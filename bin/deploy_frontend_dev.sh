#!/bin/bash

# Start the backend server
dune exec -- ftw --port=8081 --db=tests/test.db -b -v -v > bin/frontend-dev-ftw.log 2>&1 &
FTW_PID=$!
echo $FTW_PID > bin/ftw.pid

# Ensure the backend server is cleaned up on exit
cleanup() {
    if [[ -f bin/ftw.pid ]]; then
        echo "Stopping ftw task $(cat bin/ftw.pid)"
        kill -TERM $(cat bin/ftw.pid) 2>/dev/null
        echo "Stopped ftw task $(cat bin/ftw.pid)"
        rm -f bin/ftw.pid
    fi
}
trap cleanup INT TERM EXIT

echo "Running frontend server..."
(cd src/frontend && echo '{ "API_BASE_URL": "http://localhost:8082" }' > ./public/config.json && npm run dev)

echo '{ "API_BASE_URL": "http://localhost:8089" }' > ./src/frontend/public/config.json
# Wait for frontend to finish before exiting
wait $FTW_PID
echo "Ftw backend server $FTW_PID killed"
