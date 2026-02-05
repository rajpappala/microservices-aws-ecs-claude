#!/bin/bash

# Deployment script for microservices to AWS ECS
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT_NAME="microservices-demo"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "${GREEN}Starting deployment to AWS ECS${NC}"
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "Environment: $ENVIRONMENT_NAME"
echo ""

# Step 1: Create ECR repositories
echo -e "${YELLOW}Step 1: Creating ECR repositories...${NC}"
aws cloudformation deploy \
  --template-file ../infrastructure/ecr-repositories.yaml \
  --stack-name ${ENVIRONMENT_NAME}-ecr \
  --parameter-overrides EnvironmentName=${ENVIRONMENT_NAME} \
  --region ${AWS_REGION} \
  --no-fail-on-empty-changeset

# Get ECR repository URIs
SERVICE1_REPO_URI=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT_NAME}-ecr \
  --query "Stacks[0].Outputs[?OutputKey=='Service1RepositoryUri'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

SERVICE2_REPO_URI=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT_NAME}-ecr \
  --query "Stacks[0].Outputs[?OutputKey=='Service2RepositoryUri'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

echo "Service 1 ECR: $SERVICE1_REPO_URI"
echo "Service 2 ECR: $SERVICE2_REPO_URI"
echo ""

# Step 2: Build and push Docker images
echo -e "${YELLOW}Step 2: Building and pushing Docker images...${NC}"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push Service 1
echo "Building Service 1..."
cd ../service1
docker build -t service1:latest .
docker tag service1:latest ${SERVICE1_REPO_URI}:latest
echo "Pushing Service 1 to ECR..."
docker push ${SERVICE1_REPO_URI}:latest

# Build and push Service 2
echo "Building Service 2..."
cd ../service2
docker build -t service2:latest .
docker tag service2:latest ${SERVICE2_REPO_URI}:latest
echo "Pushing Service 2 to ECR..."
docker push ${SERVICE2_REPO_URI}:latest

cd ../scripts
echo ""

# Step 3: Deploy infrastructure
echo -e "${YELLOW}Step 3: Deploying ECS infrastructure...${NC}"
aws cloudformation deploy \
  --template-file ../infrastructure/cloudformation-stack.yaml \
  --stack-name ${ENVIRONMENT_NAME}-infra \
  --parameter-overrides \
    EnvironmentName=${ENVIRONMENT_NAME} \
    Service1ImageUri=${SERVICE1_REPO_URI}:latest \
    Service2ImageUri=${SERVICE2_REPO_URI}:latest \
  --capabilities CAPABILITY_IAM \
  --region ${AWS_REGION}

echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo ""

# Get outputs
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name ${ENVIRONMENT_NAME}-infra \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

echo -e "${GREEN}Your services are now available at:${NC}"
echo "API 1: http://${ALB_DNS}/api/api1"
echo "API 2: http://${ALB_DNS}/api/api2"
echo "Service 1 Health: http://${ALB_DNS}/api/health"
echo ""
echo "Note: It may take a few minutes for the services to be fully available."
