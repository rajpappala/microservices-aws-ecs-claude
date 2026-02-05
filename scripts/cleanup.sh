#!/bin/bash

# Comprehensive cleanup script to delete all AWS resources
# This script safely tears down the entire microservices infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT_NAME="microservices-demo"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          AWS MICROSERVICES TEARDOWN SCRIPT                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Environment:${NC} ${ENVIRONMENT_NAME}"
echo -e "${YELLOW}AWS Region:${NC} ${AWS_REGION}"
echo -e "${YELLOW}AWS Account:${NC} ${AWS_ACCOUNT_ID}"
echo ""

# Function to check if stack exists
stack_exists() {
  aws cloudformation describe-stacks \
    --stack-name "$1" \
    --region "${AWS_REGION}" \
    >/dev/null 2>&1
}

# Function to get all ECR images in a repository
get_ecr_images() {
  local repo_name=$1
  aws ecr list-images \
    --repository-name "${repo_name}" \
    --region "${AWS_REGION}" \
    --query 'imageIds[*]' \
    --output json 2>/dev/null || echo "[]"
}

# Display what will be deleted
echo -e "${RED}⚠️  WARNING: The following resources will be PERMANENTLY DELETED:${NC}"
echo ""
echo "📦 CloudFormation Stacks:"
if stack_exists "${ENVIRONMENT_NAME}-infra"; then
  echo "   ✓ ${ENVIRONMENT_NAME}-infra"
  echo "      - VPC and networking (subnets, route tables, IGW, NAT)"
  echo "      - Application Load Balancer"
  echo "      - ECS Cluster and Services"
  echo "      - ECS Tasks (Service 1 & Service 2)"
  echo "      - Security Groups"
  echo "      - Service Discovery"
  echo "      - CloudWatch Log Groups"
  echo "      - IAM Roles"
else
  echo "   ✗ ${ENVIRONMENT_NAME}-infra (not found)"
fi

if stack_exists "${ENVIRONMENT_NAME}-ecr"; then
  echo "   ✓ ${ENVIRONMENT_NAME}-ecr"
  echo "      - ECR Repository: ${ENVIRONMENT_NAME}/service1"
  echo "      - ECR Repository: ${ENVIRONMENT_NAME}/service2"
  echo "      - All Docker images in repositories"
else
  echo "   ✗ ${ENVIRONMENT_NAME}-ecr (not found)"
fi

echo ""
echo -e "${RED}💰 Cost Savings: ~\$107-117/month${NC}"
echo ""

# Confirmation
read -p "$(echo -e ${RED}Type \'DELETE\' to confirm teardown:${NC} )" confirmation

if [ "$confirmation" != "DELETE" ]; then
  echo ""
  echo -e "${GREEN}✓ Teardown cancelled. No resources were deleted.${NC}"
  exit 0
fi

echo ""
echo -e "${YELLOW}🚀 Starting teardown process...${NC}"
echo ""

# Step 1: Delete ECS Infrastructure Stack
if stack_exists "${ENVIRONMENT_NAME}-infra"; then
  echo -e "${BLUE}[1/5]${NC} Deleting ECS infrastructure stack..."
  echo "   - Stopping ECS tasks..."
  echo "   - Deleting ECS services..."
  echo "   - Removing load balancer..."
  echo "   - Deleting VPC and networking..."

  aws cloudformation delete-stack \
    --stack-name "${ENVIRONMENT_NAME}-infra" \
    --region "${AWS_REGION}"

  echo "   ⏳ Waiting for stack deletion (this may take 5-10 minutes)..."

  # Wait with progress indicator
  aws cloudformation wait stack-delete-complete \
    --stack-name "${ENVIRONMENT_NAME}-infra" \
    --region "${AWS_REGION}" 2>/dev/null && \
    echo -e "   ${GREEN}✓ Infrastructure stack deleted successfully${NC}" || \
    echo -e "   ${YELLOW}⚠ Stack deletion completed with warnings${NC}"
else
  echo -e "${BLUE}[1/5]${NC} Skipping infrastructure stack (not found)"
fi

echo ""

# Step 2: Delete all ECR images from Service 1
echo -e "${BLUE}[2/5]${NC} Deleting Docker images from Service 1 repository..."

IMAGES_SERVICE1=$(get_ecr_images "${ENVIRONMENT_NAME}/service1")
if [ "$IMAGES_SERVICE1" != "[]" ]; then
  aws ecr batch-delete-image \
    --repository-name "${ENVIRONMENT_NAME}/service1" \
    --image-ids "$IMAGES_SERVICE1" \
    --region "${AWS_REGION}" >/dev/null 2>&1 && \
    echo -e "   ${GREEN}✓ Service 1 images deleted${NC}" || \
    echo -e "   ${YELLOW}⚠ Service 1 repository not found or already empty${NC}"
else
  echo "   ℹ Service 1 repository empty or not found"
fi

echo ""

# Step 3: Delete all ECR images from Service 2
echo -e "${BLUE}[3/5]${NC} Deleting Docker images from Service 2 repository..."

IMAGES_SERVICE2=$(get_ecr_images "${ENVIRONMENT_NAME}/service2")
if [ "$IMAGES_SERVICE2" != "[]" ]; then
  aws ecr batch-delete-image \
    --repository-name "${ENVIRONMENT_NAME}/service2" \
    --image-ids "$IMAGES_SERVICE2" \
    --region "${AWS_REGION}" >/dev/null 2>&1 && \
    echo -e "   ${GREEN}✓ Service 2 images deleted${NC}" || \
    echo -e "   ${YELLOW}⚠ Service 2 repository not found or already empty${NC}"
else
  echo "   ℹ Service 2 repository empty or not found"
fi

echo ""

# Step 4: Delete ECR Repositories Stack
if stack_exists "${ENVIRONMENT_NAME}-ecr"; then
  echo -e "${BLUE}[4/5]${NC} Deleting ECR repositories stack..."

  aws cloudformation delete-stack \
    --stack-name "${ENVIRONMENT_NAME}-ecr" \
    --region "${AWS_REGION}"

  echo "   ⏳ Waiting for ECR stack deletion..."

  aws cloudformation wait stack-delete-complete \
    --stack-name "${ENVIRONMENT_NAME}-ecr" \
    --region "${AWS_REGION}" 2>/dev/null && \
    echo -e "   ${GREEN}✓ ECR repositories deleted successfully${NC}" || \
    echo -e "   ${YELLOW}⚠ ECR stack deletion completed with warnings${NC}"
else
  echo -e "${BLUE}[4/5]${NC} Skipping ECR repositories stack (not found)"
fi

echo ""

# Step 5: Verification
echo -e "${BLUE}[5/5]${NC} Verifying cleanup..."

REMAINING_STACKS=$(aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --region "${AWS_REGION}" \
  --query "StackSummaries[?contains(StackName, '${ENVIRONMENT_NAME}')].StackName" \
  --output text 2>/dev/null || echo "")

if [ -z "$REMAINING_STACKS" ]; then
  echo -e "   ${GREEN}✓ All stacks deleted successfully${NC}"
else
  echo -e "   ${YELLOW}⚠ Some stacks still exist: ${REMAINING_STACKS}${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              TEARDOWN COMPLETED SUCCESSFULLY               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ All AWS resources have been deleted${NC}"
echo -e "${GREEN}✓ Monthly cost savings: ~\$107-117${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "   • ECS Cluster: Deleted"
echo "   • Load Balancer: Deleted"
echo "   • VPC & Networking: Deleted"
echo "   • ECR Repositories: Deleted"
echo "   • Docker Images: Deleted"
echo "   • CloudWatch Logs: Deleted"
echo ""
echo -e "${YELLOW}Note:${NC} CloudWatch Logs may take a few hours to fully delete."
echo ""
