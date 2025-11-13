#!/bin/sh
set -e
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates >/dev/null 2>&1 || true
fi
exec wrk -t4 -c40 -d30s --latency --timeout 10s -H Host:\ localhost -H Accept:\ application/json -H Authorization:\ Bearer\ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NDUyMWE3NC00YjFhLTQ4YjQtOTY3Ny1jMjAyYzU3MTNiYjciLCJlbWFpbCI6ImFkbWluQHJvb3RseS5jb20iLCJyb2xlcyI6WyJhZG1pbiJdLCJwZXJtaXNzaW9ucyI6W10sImV4cCI6MTc2Mjk5NDI5NCwiaWF0IjoxNzYyOTc5ODk0LCJ0eXBlIjoiYWNjZXNzIn0.GTDMjTlgudEkgeaoqVHekb55WJhJzDso7nkjv3AQQj4 https://rootly-waf/api/v1/plants
