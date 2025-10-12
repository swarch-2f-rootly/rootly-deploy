#!/bin/bash

echo "=========================================="
echo "Running Integration Tests on Running Containers"
echo "=========================================="

# Analytics Backend
echo ""
echo "[1/3] Analytics Backend Integration Tests..."
docker exec be-analytics pytest tests/integration/ -v

# Authentication Backend
echo ""
echo "[2/3] Authentication Backend Integration Tests..."
docker exec be-authentication-and-roles pytest tests/integration/ -v

# Data Management Backend
echo ""
echo "[3/3] Data Management Backend Integration Tests..."
(cd ../rootly-data-management-backend && RUN_INTEGRATION_TESTS=true go test -v ./tests/integration/...)


echo ""
echo "=========================================="
echo "Integration Tests Completed!"
echo "=========================================="