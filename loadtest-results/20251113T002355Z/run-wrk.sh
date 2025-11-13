#!/bin/sh
set -e
if command -v update-ca-certificates >/dev/null 2>&1; then
  update-ca-certificates >/dev/null 2>&1 || true
fi
exec wrk -t4 -c40 -d30s --latency --timeout 10s -H Host:\ localhost -H Accept:\ application/json -H Authorization:\ Bearer\ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5NjkwODA4OC02YjU5LTRlZmMtOGM4Zi0wNTM5Y2ViYjI2MGUiLCJlbWFpbCI6ImFkbWluQHJvb3RseS5jb20iLCJyb2xlcyI6WyJhZG1pbiJdLCJwZXJtaXNzaW9ucyI6W10sImV4cCI6MTc2MzAwNzYwNiwiaWF0IjoxNzYyOTkzMjA2LCJ0eXBlIjoiYWNjZXNzIn0.B888-mssPPrFHIFM5LxIcuTc08EIjzNyEG1p78gOY40 https://rootly-waf/api/v1/plants
