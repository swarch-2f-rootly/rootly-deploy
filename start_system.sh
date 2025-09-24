#!/bin/bash

# Rootly Platform - Complete System Startup Script
# This script starts all services and initializes the database

set -e

echo "🚀 Starting Rootly Agricultural Monitoring Platform"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker and docker-compose are available
check_dependencies() {
    print_status "Checking dependencies..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi

    print_success "Dependencies check passed"
}

# Start infrastructure services
start_infrastructure() {
    print_status "Starting infrastructure services (InfluxDB, MinIO, PostgreSQL)..."

    docker-compose up -d influxdb minio postgres minio-auth

    # Wait for services to be healthy
    print_status "Waiting for infrastructure services to be ready..."
    sleep 30

    # Check if services are healthy
    if ! docker-compose ps postgres | grep -q "healthy"; then
        print_error "PostgreSQL failed to start properly"
        docker-compose logs postgres
        exit 1
    fi

    if ! docker-compose ps influxdb | grep -q "healthy"; then
        print_error "InfluxDB failed to start properly"
        docker-compose logs influxdb
        exit 1
    fi

    if ! docker-compose ps minio | grep -q "healthy"; then
        print_error "MinIO failed to start properly"
        docker-compose logs minio
        exit 1
    fi

    if ! docker-compose ps minio-auth | grep -q "healthy"; then
        print_error "MinIO Auth failed to start properly"
        docker-compose logs minio-auth
        exit 1
    fi

    print_success "Infrastructure services are running"
}

# Initialize databases
initialize_databases() {
    print_status "Initializing databases..."

    # Initialize authentication database
    if [ -d "../rootly-authentication-and-roles-backend" ]; then
        print_status "Initializing authentication database..."

        # Wait a bit more for PostgreSQL to be fully ready
        sleep 10

        # Run database initialization
        if docker run --rm --network rootly-network \
            -e DATABASE_URL="postgresql+asyncpg://auth_user:auth_password123@postgres:5432/auth_db" \
            -v "$(pwd)/../rootly-authentication-and-roles-backend/scripts:/scripts" \
            -v "$(pwd)/../rootly-authentication-and-roles-backend/src:/app/src" \
            python:3.11-slim \
            bash -c "
                cd /app/src && \
                pip install sqlalchemy asyncpg && \
                python /scripts/init_database.py
            "; then
            print_success "Authentication database initialized"
        else
            print_warning "Authentication database initialization failed (might already be initialized)"
        fi

        # Seed authentication database
        if docker run --rm --network rootly-network \
            -e DATABASE_URL="postgresql+asyncpg://auth_user:auth_password123@postgres:5432/auth_db" \
            -v "$(pwd)/../rootly-authentication-and-roles-backend/scripts:/scripts" \
            -v "$(pwd)/../rootly-authentication-and-roles-backend/src:/app/src" \
            python:3.11-slim \
            bash -c "
                cd /app/src && \
                pip install sqlalchemy asyncpg cryptography bcrypt && \
                python /scripts/seed_data.py
            "; then
            print_success "Authentication database seeded with test data"
        else
            print_warning "Authentication database seeding failed (might already be seeded)"
        fi
    else
        print_warning "Authentication backend directory not found, skipping database initialization"
    fi
}

# Start application services
start_applications() {
    print_status "Starting application services..."

    docker-compose up -d data-management-backend analytics-backend authentication-backend

    print_success "Application services started"
    print_status "Waiting for services to be fully ready..."
    sleep 30
}

# Seed data management backend with sample data
seed_data_management() {
    print_status "Seeding data management backend with sample data..."

    # Wait a bit more for the data management backend to be fully ready
    sleep 10

    # Check if data management backend is healthy
    if ! docker-compose exec -T data-management-backend curl -f http://localhost:8080/health &>/dev/null; then
        print_error "Data management backend is not healthy, skipping seeding"
        return 1
    fi

    # Run the seeding script
    if docker run --rm --network rootly-network \
        -v "$(pwd)/../rootly-data-management-backend:/app" \
        -w /app \
        golang:1.21-alpine \
        sh -c "
            apk add --no-cache git ca-certificates && \
            go run scripts/seed_data.go
        "; then
        print_success "Data management backend seeded with sample agricultural data"
    else
        print_warning "Data management backend seeding failed (might already be seeded)"
    fi
}

# Display service information
display_info() {
    echo ""
    print_success "🎉 Rootly Platform Started Successfully!"
    echo ""
    echo "📊 Available Services:"
    echo "  🌐 API Gateway:     http://localhost:8080"
    echo "  📈 Analytics API:   http://localhost:8000"
    echo "  🔐 Auth API:        http://localhost:8001"
    echo ""
    echo "📚 API Documentation:"
    echo "  📊 Analytics:       http://localhost:8000/docs"
    echo "  🔐 Authentication:  http://localhost:8001/docs"
    echo ""
    echo "👥 Test Users (Authentication Service):"
    echo "  Admin:     admin@rootly.com     / Admin123!"
    echo "  Farmer:    farmer@rootly.com    / Farmer123!"
    echo "  Technician: tech@rootly.com     / Tech123!"
    echo "  Manager:   manager@rootly.com   / Manager123!"
    echo ""
    echo "🔧 Management Commands:"
    echo "  View logs:        docker-compose logs -f [service-name]"
    echo "  Stop services:    docker-compose down"
    echo "  Restart service:  docker-compose restart [service-name]"
    echo ""
    print_warning "⚠️  Remember to change default passwords in production!"
}

# Main execution
main() {
    check_dependencies
    start_infrastructure
    initialize_databases
    start_applications
    seed_data_management
    display_info
}

# Run main function
main "$@"
