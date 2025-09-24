#!/bin/bash

# Rootly Platform Setup Script
# This script helps set up all services with their environment files

set -e

echo "🚀 Setting up Rootly Platform..."

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

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "Please run this script from the rootly-deployment directory"
    exit 1
fi

# Setup Analytics Backend
print_status "Setting up Analytics Backend..."
if [ -f "../rootly-analytics-backend/.env.example" ]; then
    if [ ! -f "../rootly-analytics-backend/.env" ]; then
        cp ../rootly-analytics-backend/.env.example ../rootly-analytics-backend/.env
        print_success "Created .env file for Analytics Backend"
    else
        print_warning ".env file already exists for Analytics Backend"
    fi
else
    print_error ".env.example not found for Analytics Backend"
    exit 1
fi

# Setup Data Management Backend
print_status "Setting up Data Management Backend..."
if [ -f "../rootly-data-management-backend/.env.example" ]; then
    if [ ! -f "../rootly-data-management-backend/.env" ]; then
        cp ../rootly-data-management-backend/.env.example ../rootly-data-management-backend/.env
        print_success "Created .env file for Data Management Backend"
    else
        print_warning ".env file already exists for Data Management Backend"
    fi
else
    print_error ".env.example not found for Data Management Backend"
    exit 1
fi

# Setup Authentication Backend
print_status "Setting up Authentication Backend..."
if [ -f "../rootly-authentication-and-roles-backend/.env.example" ]; then
    if [ ! -f "../rootly-authentication-and-roles-backend/.env" ]; then
        cp ../rootly-authentication-and-roles-backend/.env.example ../rootly-authentication-and-roles-backend/.env
        print_success "Created .env file for Authentication Backend"
    else
        print_warning ".env file already exists for Authentication Backend"
    fi
else
    print_error ".env.example not found for Authentication Backend"
    exit 1
fi

print_success "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and customize the .env files in each service directory if needed"
echo "2. Run: docker-compose up -d"
echo "3. Check status: docker-compose ps"
echo ""
echo "Service endpoints:"
echo "- Authentication Backend: http://localhost:8001"
echo "- Analytics Backend: http://localhost:8000"
echo "- Data Management Backend: http://localhost:8080"
echo "- InfluxDB: http://localhost:8086"
echo "- MinIO Console: http://localhost:9001"
echo "- MinIO Auth Console: http://localhost:9003"
echo "- PostgreSQL: localhost:5432"
