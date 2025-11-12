#!/bin/sh
set -e
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates >/dev/null 2>&1 || true
fi
exec wrk -t4 -c40 -d30s --latency --timeout 10s -H Host:\ localhost -H Accept:\ application/json -H Authorization:\ Bearer\ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2M2U3YzFmMy00NzgwLTRkOGEtYTQ2OC02YmFmYTIyMmMwMjMiLCJlbWFpbCI6ImFkbWluQHJvb3RseS5jb20iLCJyb2xlcyI6WyJhZG1pbiJdLCJwZXJtaXNzaW9ucyI6W10sImV4cCI6MTc2Mjk5MDM2OSwiaWF0IjoxNzYyOTc1OTY5LCJ0eXBlIjoiYWNjZXNzIn0.WFFfp1yblu6TrohCGhvRKT_oxzrEb3ttSunaiKnIiB0 https://rootly-waf/api/v1/plants
