# Rootly Deployment

This directory contains the unified deployment configuration for the entire Rootly agricultural monitoring platform.

## Architecture Overview

The platform consists of the following main services:

### Infrastructure Services

1. **InfluxDB** - Time-series database for sensor data storage
2. **MinIO Data Lake** - Object storage for raw data files
3. **PostgreSQL Authentication** - Relational database for user management and authentication
4. **MinIO Auth** - Object storage for user profile photos
5. **PostgreSQL User Plant Management** - Relational database for user plant data
6. **MinIO User Plant** - Object storage for user plant files
7. **Kafka** - Message queue for data ingestion
8. **Zookeeper** - Coordination service for Kafka

### Application Services

9. **Data Ingestion Backend** (Python) - Handles data ingestion through Kafka
10. **Data Processing Backend** (Python) - Processes and stores data in InfluxDB and MinIO
11. **Analytics Backend** (Python) - Provides analytics and insights
12. **Authentication Backend** (Python) - Handles user authentication and management
13. **User Plant Management Backend** (Python) - Handles user plant management
14. **API Gateway** (Go) - GraphQL + REST proxy with JWT authentication
15. **Frontend SSR** (Next.js) - Server-side rendered user interface for the agricultural monitoring platform
16. **Rootly WAF** (Nginx + ModSecurity) - HTTPS termination and application-layer protection in front of the public entry point

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 6GB RAM available
- Ports available:
  - Application Services: 80, 443, 8000, 8001, 8002, 8003, 8005, 8080
  - Infrastructure: 8086 (InfluxDB), 9092 (Kafka), 2181 (Zookeeper), 8082 (Kafka UI)
  - Storage: 9000-9005 (MinIO ports and consoles)
  - Databases: 5432, 5433 (PostgreSQL)

### Quick Setup (Recommended)

#### Automated Start

```bash
cd rootly-deployment
./start.sh
```

This script automatically:

- Copies `.env.example` to `.env` if it doesn't exist (for deployment and frontend)
- Detects your LAN IP address for external access
- Starts all services with Docker Compose
- Displays service endpoints and health check URLs

#### Manual Setup

1. **Clone the repository** (if not already done)

2. **Navigate to deployment directory**

    ```bash
    cd rootly-deployment
    ```

3. **Configure environment variables**

    Copy `.env.example` to `.env` and edit if needed:

    ```bash
    cp .env.example .env
    # Edit .env file if needed
    ```

    Also for the frontend:

    ```bash
    cp ../rootly-frontend/.env.example ../rootly-frontend/.env
    # Edit if needed
    ```

4. **Start all services**

    ```bash
  docker-compose up -d --build
    ```

5. **Check service health**

    ```bash
    docker-compose ps
    ```

### Manual Setup

If you prefer to configure each service manually:

1. **Clone the repository** (if not already done)

2. **Navigate to deployment directory**

   ```bash
   cd rootly-deployment
   ```

3. **Configure environment variables for each service**

   **For Analytics Backend:**

   ```bash
   cd ../rootly-analytics-backend
   cp .env.example .env
   # Edit .env file if needed
   cd ../rootly-deployment
   ```

   **For Data Ingestion Backend:**

   ```bash
   cd ../rootly-data-ingestion
   cp .env.example .env
   # Edit .env file if needed
   cd ../rootly-deployment
   ```

   **For Data Processing Backend:**

   ```bash
   cd ../rootly-data-processing
   cp .env.example .env
   # Edit .env file if needed
   cd ../rootly-deployment
   ```

4. **Start all services**

   ```bash
   docker-compose up -d
   ```

5. **Check service health**

   ```bash
   docker-compose ps
   ```

## Service Endpoints

Once started, the services will be available at:

- **Authentication Backend**: <http://localhost:8001>
  - API Documentation: <http://localhost:8001/docs>
  - Health Check: <http://localhost:8001/health>

- **Analytics Backend**: <http://localhost:8000>
  - API Documentation: <http://localhost:8000/docs>
  - Health Check: <http://localhost:8000/health>

- **Data Processing Backend**: <http://localhost:8002>
  - API Documentation: <http://localhost:8002/docs>
  - Health Check: <http://localhost:8002/health>

- **Data Ingestion Backend**: <http://localhost:8005>
  - API Documentation: <http://localhost:8005/docs>
  - Health Check: <http://localhost:8005/health>

- **User Plant Management Backend**: <http://localhost:8003>
  - Health Check: <http://localhost:8003/health>

- **Rootly WAF**: <https://localhost> (certificado autofirmado en desarrollo)
  - Fallback HTTP: <http://localhost>
  - Rutas protegidas: `/`, `/api/`, `/graphql`

- **Frontend SSR**: expuesto a través del WAF (`https://localhost`)

- **API Gateway**: expuesto mediante el WAF (`https://localhost/graphql`)
  - Health (externo): `https://localhost/api/health` (proxied)
  - Health interno: `http://api-gateway:8080/health`
  - GraphQL Playground externo: `https://localhost/graphql`

- **InfluxDB**: <http://localhost:8086>
  - Admin UI: Access via web browser
  - Credentials: admin / admin123

- **MinIO (Data Lake)**: <http://localhost:9000>
  - Console: <http://localhost:9001>
  - Credentials: admin / admin123

- **MinIO Auth (Profile Photos)**: <http://localhost:9002>
  - Console: <http://localhost:9003>
  - Credentials: admin / admin123

- **MinIO User Plant**: <http://localhost:9004>
  - Console: <http://localhost:9005>
  - Credentials: admin / admin123

- **Kafka UI**: <http://localhost:8082>
  - Kafka queue management interface

- **PostgreSQL Authentication**: localhost:5432
  - Database: authentication_and_roles_db
  - User: admin
  - Password: admin123

- **PostgreSQL User Plant Management**: localhost:5433
  - Database: user_plant_management_db
  - User: admin
  - Password: admin123

## Service Dependencies

The services start in the correct order with health checks:

```
Infrastructure Services:
- Zookeeper (zookeeper-data-ingestion)
- Kafka (queue-data-ingestion) - depends on Zookeeper
- Kafka UI (queue-ui-data-ingestion) - depends on Kafka
- InfluxDB (db-data-processing)
- MinIO Data Lake (stg-data-processing)
- PostgreSQL Auth (db-authentication-and-roles)
- MinIO Auth (stg-authentication-and-roles)
- PostgreSQL User Plant (db-user-plant-management)
- MinIO User Plant (stg-user-plant-management)

Application Services:
- Data Ingestion Backend (depends on Kafka)
- Data Processing Backend (depends on InfluxDB + MinIO Data + Kafka)
- Analytics Backend (depends on InfluxDB + MinIO Data)
- Authentication Backend (depends on PostgreSQL Auth + MinIO Auth)
- User Plant Management Backend (depends on PostgreSQL User Plant + MinIO User Plant)
- API Gateway (depends on all backend services)
- Frontend SSR (depends on API Gateway)
- Reverse proxy (internal) (depends on Frontend SSR + API Gateway)
- Rootly WAF (depends on reverse proxy)
```

## Development Commands

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f analytics-backend
```

### Restart a service

```bash
docker-compose restart analytics-backend
```

### Rebuild and restart

```bash
docker-compose up --build -d analytics-backend
```

### Stop all services

```bash
docker-compose down
```

### Clean up (removes volumes)

```bash
docker-compose down -v
```

## Configuration

### Environment Variables

All configuration is handled through the `.env` file. Key variables:

#### Infrastructure

- `INFLUXDB_*` - InfluxDB configuration
- `MINIO_*` - MinIO configuration
- `KAFKA_*` - Kafka message queue configuration
- `ZOOKEEPER_*` - Zookeeper configuration

#### Applications

- `DATA_INGESTION_PORT` - Data ingestion backend port (default: 8005)
- `DATA_PROCESSING_PORT` - Data processing backend port (default: 8002)
- `ANALYTICS_PORT` - Analytics backend port (default: 8000)
- `AUTH_PORT` - Authentication backend port (default: 8001)
- `USER_PLANT_MANAGEMENT_PORT` - User plant management backend port (default: 8003)
- `API_GATEWAY_PORT` - API Gateway port (default: 8080)
- `ROOTLY_WAF_HTTP_PORT` / `ROOTLY_WAF_HTTPS_PORT` - WAF exposed ports (default: 80 / 443)

### Networking

All services communicate through the `rootly-network` Docker network:

- Services can reach each other by container name
- External access through published ports only

### Volumes

Persistent data is stored in named volumes:

- `influxdb_data` - InfluxDB database files
- `minio_data` - MinIO data lake object storage files
- `postgres_data` - PostgreSQL authentication database files
- `minio_auth_data` - MinIO auth object storage files
- `postgres_user_plant_data` - PostgreSQL user plant management database files
- `minio_user_plant_data` - MinIO user plant object storage files

## Testing

To run integration tests on the running containers, use the test script:

```bash
cd rootly-deployment
./test.sh
```

This script runs integration tests for:

- Analytics Backend (Python pytest)
- Authentication Backend (Python pytest)
- Data Ingestion Backend (Go tests)
- Data Processing Backend (Go tests)

## Monitoring

### Health Checks

All services include health checks that verify:

- InfluxDB: Database connectivity
- MinIO: Object storage availability
- Backends: HTTP endpoint responsiveness

### Logs

Application logs are available via:

```bash
docker-compose logs -f [service-name]
```

## Security Notes

- Change default passwords in production
- Use strong tokens for InfluxDB
- Consider using secrets management for sensitive data
- MinIO console should be protected in production

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure the following ports are available:
   - Application Services: 80, 443, 8000, 8001, 8002, 8003, 8005, 8080
   - Infrastructure: 8086 (InfluxDB), 9092 (Kafka), 2181 (Zookeeper), 8082 (Kafka UI)
   - Storage: 9000-9005 (MinIO ports and consoles)
   - Databases: 5432, 5433 (PostgreSQL)
2. **Memory issues**: Ensure at least 6GB RAM available
3. **Slow startup**: First run may take several minutes due to health checks
4. **Kafka connection issues**: Ensure Zookeeper is running before Kafka starts

### Debug Commands

```bash
# Check service status
docker-compose ps

# Check resource usage
docker stats

# Inspect networks
docker network ls
docker network inspect rootly-network
```

## Additional Resources

- [InfluxDB Documentation](https://docs.influxdata.com/influxdb/)
- [MinIO Documentation](https://min.io/docs/minio/linux/index.html)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
