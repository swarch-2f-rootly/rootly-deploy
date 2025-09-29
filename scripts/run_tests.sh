#!/bin/bash
set -e

echo "Running tests..."
docker compose -f ../rootly-deployment/docker-compose.yml run --build --rm user-plant-management-backend pytest
