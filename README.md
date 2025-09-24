# Rootly Deployment

This directory contains the unified deployment configuration for the entire Rootly agricultural monitoring platform.

## 🏗️ Architecture Overview

The platform consists of six main services:

### Infrastructure Services:
1. **InfluxDB** - Time-series database for sensor data storage
2. **MinIO** - Object storage for raw data files (data lake)
3. **PostgreSQL** - Relational database for user management and authentication
4. **MinIO Auth** - Object storage for user profile photos

### Application Services:
5. **Data Management Backend** (Go) - Handles data ingestion and management
6. **Analytics Backend** (Python) - Provides analytics and insights
7. **Authentication Backend** (Python) - Handles user authentication and management

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 6GB RAM available
- Ports 8000, 8001, 8080, 8086, 9000, 9001, 9002, 9003, 5432 available

### Quick Setup (Recommended)

#### Opción A: Inicio Completamente Automático
```bash
cd rootly-deployment
./start_system.sh
```

Este script hace todo automáticamente:
- ✅ Inicia servicios de infraestructura (PostgreSQL, InfluxDB, MinIO)
- ✅ Inicializa bases de datos con esquemas y datos de prueba
- ✅ Inicia servicios de aplicación
- ✅ Muestra información de acceso

#### Opción B: Setup Paso a Paso

1. **Clone the repository** (if not already done)

2. **Navigate to deployment directory**
   ```bash
   cd rootly-deployment
   ```

3. **Run setup script**
   ```bash
   ./setup.sh
   ```

4. **Start all services**
   ```bash
   docker-compose up -d
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

   **For Data Management Backend:**
   ```bash
   cd ../rootly-data-management-backend
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

## 🔍 Service Endpoints

Once started, the services will be available at:

- **Authentication Backend**: http://localhost:8001
  - API Documentation: http://localhost:8001/docs
  - Health Check: http://localhost:8001/health

- **Analytics Backend**: http://localhost:8000
  - API Documentation: http://localhost:8000/docs
  - Health Check: http://localhost:8000/health

- **Data Management Backend**: http://localhost:8080
  - GraphQL Playground: http://localhost:8080/

- **InfluxDB**: http://localhost:8086
  - Admin UI: Access via web browser

- **MinIO (Data Lake)**: http://localhost:9000
  - Console: http://localhost:9001
  - Credentials: minioadmin / minioadmin123

- **MinIO Auth (Profile Photos)**: http://localhost:9002
  - Console: http://localhost:9003
  - Credentials: minioauth / minioauth123

- **PostgreSQL**: localhost:5432
  - Database: auth_db
  - User: auth_user

## 📊 Service Dependencies

The services start in the correct order with health checks:

```
InfluxDB & MinIO (Infrastructure)
    ↳ Data Management Backend (depends on both)
    ↳ Analytics Backend (depends on InfluxDB only)
```

## 🛠️ Development Commands

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

## 🔧 Configuration

### Environment Variables

All configuration is handled through the `.env` file. Key variables:

#### Infrastructure
- `INFLUXDB_*` - InfluxDB configuration
- `MINIO_*` - MinIO configuration

#### Applications
- `DATA_MANAGEMENT_PORT` - Data management backend port (default: 8080)
- `ANALYTICS_PORT` - Analytics backend port (default: 8000)

### Networking

All services communicate through the `rootly-network` Docker network:
- Services can reach each other by container name
- External access through published ports only

### Volumes

Persistent data is stored in named volumes:
- `influxdb_data` - InfluxDB database files
- `minio_data` - MinIO object storage files

## 🧪 Testing

For integration testing, use the test-specific configuration in the data-management-backend:

```bash
cd ../rootly-data-management-backend
docker-compose -f tests/integration/docker-compose.test.yml up -d
```

## 📈 Monitoring

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

## 🔒 Security Notes

- Change default passwords in production
- Use strong tokens for InfluxDB
- Consider using secrets management for sensitive data
- MinIO console should be protected in production

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 8000, 8080, 8086, 9000, 9001 are available
2. **Memory issues**: Ensure at least 4GB RAM available
3. **Slow startup**: First run may take several minutes due to health checks

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

## 📚 Additional Resources

- [InfluxDB Documentation](https://docs.influxdata.com/influxdb/)
- [MinIO Documentation](https://min.io/docs/minio/linux/index.html)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
