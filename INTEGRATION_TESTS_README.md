# Integration Tests

This directory contains the integration test setup for the Rootly platform.

## Overview

The integration tests are designed to test the complete system end-to-end, including:
- HTTP API endpoints
- Database operations (InfluxDB)
- Object storage operations (MinIO)
- Service health checks

## Architecture

The integration tests run in isolated Docker containers to avoid conflicts with development/production environments:

- **influxdb-test**: Test InfluxDB instance (port 8087)
- **minio-test**: Test MinIO instance (port 9004/9005)
- **data-management-backend-test**: Test application instance (port 8080)
- **integration-tests**: Test runner container

## Files

- `docker-compose.test.yml`: Docker Compose configuration for test environment
- `.env.test`: Environment variables for test environment
- `run-integration-tests.sh`: Convenience script to run tests
- `../rootly-data-management-backend/Dockerfile.test`: Test-specific Dockerfile

## Running Tests

### Method 1: Using the convenience script (Recommended)

```bash
cd rootly-deployment
./run-integration-tests.sh
```

### Method 2: Manual Docker Compose commands

```bash
cd rootly-deployment

# Start test infrastructure
docker-compose -f docker-compose.test.yml up -d influxdb-test minio-test data-management-backend-test

# Wait for services to be ready (check logs)
docker-compose -f docker-compose.test.yml logs -f

# Run tests
docker-compose -f docker-compose.test.yml --profile tests up integration-tests

# Cleanup
docker-compose -f docker-compose.test.yml down -v
```

### Method 3: Running tests locally (without Docker)

```bash
cd rootly-data-management-backend

# Make sure the main application is running on localhost:8080
# Then run:
RUN_INTEGRATION_TESTS=true go test -v ./tests/integration/... -run TestIntegrationTestSuite
```

## Test Configuration

The test environment uses separate:
- Database: `rootly-test` organization, `agricultural_data_test` bucket
- Object storage: `raw-data-test` bucket
- Ports: Different ports to avoid conflicts with development environment

## Test Structure

The integration tests in `main_test.go` include:

- **Health Check**: Verifies the application is responding
- **Data Ingestion**: Tests POST requests to `/api/v1/measurements`
- **Validation**: Tests error handling for invalid data
- **Multiple Measurements**: Tests concurrent request handling
- **HTTP Methods**: Tests method restrictions
- **Data Persistence**: Framework for future persistence validation

## Environment Variables

Key test environment variables (defined in `.env.test`):

- `RUN_INTEGRATION_TESTS=true`: Enables test mode
- `INFLUXDB_PORT=8087`: Test InfluxDB port
- `MINIO_PORT=9004`: Test MinIO port
- `DATA_MANAGEMENT_EXTERNAL_PORT=8080`: Test application port

## Troubleshooting

### Tests fail to connect

1. Check that all services are healthy:
   ```bash
   docker-compose -f docker-compose.test.yml ps
   ```

2. Check service logs:
   ```bash
   docker-compose -f docker-compose.test.yml logs [service-name]
   ```

### Port conflicts

If you get port conflicts, the test ports may already be in use. Check:
```bash
netstat -tlnp | grep -E ':(8087|9004|9005|8080)'
```

### Cleanup stuck containers

```bash
docker-compose -f docker-compose.test.yml down -v --remove-orphans
docker system prune -f
```

## Adding New Tests

1. Add test methods to `IntegrationTestSuite` in `main_test.go`
2. Follow the existing pattern: Given-When-Then structure
3. Use `suite.httpClient` for HTTP requests
4. Use `getTestServerURL()` for service URLs (works in both Docker and local environments)