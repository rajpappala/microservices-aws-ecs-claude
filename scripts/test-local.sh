#!/bin/bash

# Script to test services locally with Docker
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting local testing with Docker...${NC}"

# Build Docker images
echo "Building Service 2..."
cd ../service2
docker build -t service2:local .

echo "Building Service 1..."
cd ../service1
docker build -t service1:local .

cd ../scripts

# Create Docker network
echo "Creating Docker network..."
docker network create microservices-network 2>/dev/null || true

# Stop and remove existing containers
echo "Cleaning up existing containers..."
docker stop service1 service2 2>/dev/null || true
docker rm service1 service2 2>/dev/null || true

# Start Service 2 (backend)
echo "Starting Service 2..."
docker run -d \
  --name service2 \
  --network microservices-network \
  -p 8081:8080 \
  service2:local

# Wait for Service 2 to be ready
echo "Waiting for Service 2 to be ready..."
sleep 10

# Start Service 1 (gateway)
echo "Starting Service 1..."
docker run -d \
  --name service1 \
  --network microservices-network \
  -p 8080:8080 \
  -e SERVICE2_URL=http://service2:8080 \
  service1:local

# Wait for Service 1 to be ready
echo "Waiting for Service 1 to be ready..."
sleep 10

echo -e "${GREEN}Services started successfully!${NC}"
echo ""
echo "Test the endpoints:"
echo "  Service 1 Health: curl http://localhost:8080/api/health"
echo "  Service 2 Health: curl http://localhost:8081/api/health"
echo "  API 1 (calls Service 2 endpoint1): curl http://localhost:8080/api/api1"
echo "  API 2 (calls Service 2 endpoint2): curl http://localhost:8080/api/api2"
echo ""
echo "View logs:"
echo "  Service 1: docker logs -f service1"
echo "  Service 2: docker logs -f service2"
echo ""
echo "To stop: docker stop service1 service2"
