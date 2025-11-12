#!/bin/sh
set -e
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates >/dev/null 2>&1 || true
fi
exec wrk -t4 -c40 -d5s --latency --timeout 10s -H Host:\ localhost -H Accept:\ application/json -H Authorization:\ Bearer\ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhOWE0NTNhNy1kMWJmLTRiNjctYWRkMC1hNTBlYTMzN2Q1OTAiLCJlbWFpbCI6ImFkbWluQHJvb3RseS5jb20iLCJyb2xlcyI6WyJhZG1pbiJdLCJwZXJtaXNzaW9ucyI6W10sImV4cCI6MTc2Mjk4MDUxMSwiaWF0IjoxNzYyOTY2MTExLCJ0eXBlIjoiYWNjZXNzIn0.-SAcbekii-FHJsFo-SQ6ofqVrSqyR__BoYliqLu5S5A https://rootly-waf/api/v1/plants
