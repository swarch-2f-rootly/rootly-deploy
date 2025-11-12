#!/bin/sh
set -e
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates >/dev/null 2>&1 || true
fi
exec wrk -t4 -c40 -d5s --latency --timeout 10s -H Host:\ localhost -H Accept:\ application/json -H Authorization:\ Bearer\ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2ZmFjZDg0Ny0wNTk3LTQyMjUtYWI0Zi03YzU5NzcxZjQ1MzQiLCJlbWFpbCI6ImFkbWluQHJvb3RseS5jb20iLCJyb2xlcyI6WyJhZG1pbiJdLCJwZXJtaXNzaW9ucyI6W10sImV4cCI6MTc2Mjk4NzY0OSwiaWF0IjoxNzYyOTczMjQ5LCJ0eXBlIjoiYWNjZXNzIn0.2H_17LNtow3zHgMJ28Fvk-o32WMtfZMwQEGjPzYbW3A https://rootly-waf/api/v1/plants
