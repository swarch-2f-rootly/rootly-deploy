#!/bin/bash

# Rootly Integration Tests Runner
# This script runs the integration tests in isolated Docker containers

set -e

echo "🧪 Starting Rootly Integration Tests..."

# Change to the deployment directory
cd "$(dirname "$0")"

# Function to cleanup on exit
cleanup() {
    echo "🧹 Cleaning up test containers..."
    docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Cleanup any existing test containers
echo "🧹 Cleaning up existing test containers..."
docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>/dev/null || true

# Start the test infrastructure and application
echo "🏗️  Starting test infrastructure..."
docker-compose -f docker-compose.test.yml up -d influxdb-test minio-test data-management-backend-test

# Wait for services to be ready
echo "⏳ Waiting for services to be healthy..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "Checking services health (attempt $attempt/$max_attempts)..."

    # Check InfluxDB
    if ! docker-compose -f docker-compose.test.yml exec -T influxdb-test influx ping 2>/dev/null; then
        echo "  ❌ InfluxDB not ready"
        influx_ready=false
    else
        echo "  ✅ InfluxDB ready"
        influx_ready=true
    fi

    # Check MinIO
    if ! docker-compose -f docker-compose.test.yml exec -T minio-test curl -f http://localhost:9100/minio/health/live 2>/dev/null; then
        echo "  ❌ MinIO not ready"
        minio_ready=false
    else
        echo "  ✅ MinIO ready"
        minio_ready=true
    fi

    # Check Application
    if ! docker-compose -f docker-compose.test.yml exec -T data-management-backend-test curl -f http://localhost:8102/health 2>/dev/null; then
        echo "  ❌ Application not ready"
        app_ready=false
    else
        echo "  ✅ Application ready"
        app_ready=true
    fi

    # If all services are ready, break
    if [ "$influx_ready" = true ] && [ "$minio_ready" = true ] && [ "$app_ready" = true ]; then
        echo "🎉 All services are ready!"
        break
    fi

    # Wait before next attempt
    sleep 5
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Services failed to become ready within timeout"
    exit 1
fi

# Run the integration tests
echo "🧪 Running integration tests..."
docker-compose -f docker-compose.test.yml --profile tests up integration-tests

# Check test results
test_exit_code=$?

if [ $test_exit_code -eq 0 ]; then
    echo "✅ All integration tests passed!"
else
    echo "❌ Integration tests failed with exit code $test_exit_code"
    exit $test_exit_code
fi
