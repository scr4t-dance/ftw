#!/bin/bash

# Start the backend server
dune exec -- ftw --db=tests/test.db > bin/frontend-dev-ftw.log 2>&1 &
FTW_PID=$!
echo $FTW_PID > bin/ftw.pid

# Ensure the backend server is cleaned up on exit
cleanup() {
    if [[ -f bin/ftw.pid ]]; then
        kill -TERM $(cat bin/ftw.pid) 2>/dev/null
        echo "Stopped ftw task"
        rm -f bin/ftw.pid
    fi
}
trap cleanup INT TERM EXIT

echo "Running frontend server..."
(cd src/frontend && npm run dev)

# Wait for frontend to finish before exiting
wait $FTW_PID
echo "Ftw backend server killed."
