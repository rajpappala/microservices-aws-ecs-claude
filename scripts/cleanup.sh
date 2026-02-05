#!/bin/bash

# Cleanup script to delete all AWS resources
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT_NAME="microservices-demo"

echo -e "${RED}WARNING: This will delete all resources created for ${ENVIRONMENT_NAME}${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo -e "${YELLOW}Starting cleanup...${NC}"

# Delete ECS infrastructure stack
echo "Deleting ECS infrastructure..."
aws cloudformation delete-stack \
  --stack-name ${ENVIRONMENT_NAME}-infra \
  --region ${AWS_REGION} 2>/dev/null || true

echo "Waiting for infrastructure stack deletion..."
aws cloudformation wait stack-delete-complete \
  --stack-name ${ENVIRONMENT_NAME}-infra \
  --region ${AWS_REGION} 2>/dev/null || true

# Delete ECR images before deleting repositories
echo "Deleting ECR images..."
aws ecr batch-delete-image \
  --repository-name ${ENVIRONMENT_NAME}/service1 \
  --image-ids imageTag=latest \
  --region ${AWS_REGION} 2>/dev/null || true

aws ecr batch-delete-image \
  --repository-name ${ENVIRONMENT_NAME}/service2 \
  --image-ids imageTag=latest \
  --region ${AWS_REGION} 2>/dev/null || true

# Delete ECR repositories stack
echo "Deleting ECR repositories..."
aws cloudformation delete-stack \
  --stack-name ${ENVIRONMENT_NAME}-ecr \
  --region ${AWS_REGION} 2>/dev/null || true

echo "Waiting for ECR stack deletion..."
aws cloudformation wait stack-delete-complete \
  --stack-name ${ENVIRONMENT_NAME}-ecr \
  --region ${AWS_REGION} 2>/dev/null || true

echo -e "${GREEN}Cleanup completed!${NC}"
