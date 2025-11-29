#!/bin/sh
set -e
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates >/dev/null 2>&1 || true
fi
exec wrk -t4 -c40 -d30s --latency --timeout 10s -H Host:\ localhost -H Accept:\ application/json -H Authorization:\ Bearer\ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5ZGI1NDRkNy0zZWRjLTRkZTUtOGY3ZC00Y2Q0OTQzM2ZiMjgiLCJlbWFpbCI6ImFkbWluQHJvb3RseS5jb20iLCJyb2xlcyI6WyJhZG1pbiJdLCJwZXJtaXNzaW9ucyI6W10sImV4cCI6MTc2MzA2NTgwOCwiaWF0IjoxNzYzMDUxNDA4LCJ0eXBlIjoiYWNjZXNzIn0.Vet8YBBzhdZb2I0mGtgiQrr8YumfRIc96kHliJMcMhc https://rootly-waf/api/v1/plants
