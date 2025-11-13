#!/bin/sh
set -e
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates >/dev/null 2>&1 || true
fi
exec wrk -t4 -c40 -d30s --latency --timeout 10s -H Host:\ localhost -H Accept:\ application/json -H Authorization:\ Bearer\ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwOTc4MjMyOS1jZDkzLTQwZTQtOTU0MC1hZmUwM2RjMjMxZWEiLCJlbWFpbCI6ImFkbWluQHJvb3RseS5jb20iLCJyb2xlcyI6WyJhZG1pbiJdLCJwZXJtaXNzaW9ucyI6W10sImV4cCI6MTc2MzAwMzc1MywiaWF0IjoxNzYyOTg5MzUzLCJ0eXBlIjoiYWNjZXNzIn0.mr0OGgHJtO4ZxVgVMKd5roZSto_71hl3MFm42NXH9ps https://rootly-waf/api/v1/plants
