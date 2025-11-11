#!/bin/bash

echo "=========================================="
echo "Running Integration Tests on Running Containers"
echo "=========================================="

# Analytics Backend
echo ""
echo "[1/4] Analytics Backend Integration Tests..."
docker exec be-analytics pytest tests/integration/ -v

# Authentication Backend
echo ""
echo "[2/4] Authentication Backend Integration Tests..."
docker exec be-authentication-and-roles pytest tests/integration/ -v

# Data Ingestion Backend
echo ""
echo "[3/4] Data Ingestion Backend Integration Tests..."
(cd ../rootly-data-ingestion && RUN_INTEGRATION_TESTS=true go test -v ./tests/integration/...)

# Data Processing Backend
echo ""
echo "[4/4] Data Processing Backend Integration Tests..."
(cd ../rootly-data-processing && RUN_INTEGRATION_TESTS=true go test -v ./tests/integration/...)


echo ""
echo "=========================================="
echo "Integration Tests Completed!"
echo "=========================================="