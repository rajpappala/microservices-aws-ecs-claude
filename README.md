# Microservices on AWS ECS with GitHub Actions CI/CD

Complete microservices solution with Spring Boot, Docker, AWS ECS, and automated CI/CD using GitHub Actions.

## 🚀 Features

- ✅ 2 Spring Boot microservices (Java 17)
- ✅ Service-to-service communication
- ✅ Docker containerization
- ✅ AWS ECS Fargate deployment
- ✅ Private networking for backend service
- ✅ Application Load Balancer
- ✅ CloudFormation Infrastructure as Code
- ✅ **GitHub Actions CI/CD pipeline**
- ✅ Automated deployments on every commit
- ✅ Pull request checks

## 📋 Architecture

```
Internet → ALB (Public) → Service 1 (Public Subnet)
                            ↓
                          Service 2 (Private Subnet)
```

**Service 1** - API Gateway (Public)
- `/api/api1` → calls Service 2's endpoint1
- `/api/api2` → calls Service 2's endpoint2
- `/api/health` → health check

**Service 2** - Backend (Private)
- `/api/endpoint1` → returns sample data
- `/api/endpoint2` → returns sample data
- `/api/health` → health check
- **Only accessible from Service 1**

## 🔄 CI/CD Pipeline

```
Push to GitHub → Build & Test → Docker Build → Push to ECR → Deploy to ECS
```

**Automated on every push to main branch:**
1. Build and test both services
2. Build Docker images
3. Push to AWS ECR
4. Deploy to ECS via CloudFormation
5. Health check verification

## 📁 Project Structure

```
microservices-aws-ecs/
├── .github/
│   └── workflows/
│       ├── deploy.yml          # Main CI/CD pipeline
│       ├── pr-check.yml        # PR validation
│       └── cleanup.yml         # Resource cleanup
├── service1/                   # Service 1 (API Gateway)
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── service2/                   # Service 2 (Backend)
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── infrastructure/             # CloudFormation templates
│   ├── ecr-repositories.yaml
│   └── cloudformation-stack.yaml
├── scripts/                    # Deployment scripts
│   ├── deploy.sh
│   ├── cleanup.sh
│   └── test-local.sh
├── GITHUB_SETUP.md            # GitHub CI/CD setup guide
└── README.md
```

## 🚦 Quick Start

### 1. Test Locally (5 minutes)

```bash
cd microservices-aws-ecs/scripts
./test-local.sh

# Test endpoints
curl http://localhost:8080/api/api1 | jq
curl http://localhost:8080/api/api2 | jq
```

### 2. Set Up GitHub CI/CD (10 minutes)

**Step 1: Create GitHub Repository**
```bash
cd microservices-aws-ecs
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/microservices-aws-ecs.git
git push -u origin main
```

**Step 2: Add AWS Credentials to GitHub**
1. Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

**Step 3: Push and Deploy**
```bash
git push origin main
```

GitHub Actions will automatically:
- Build and test
- Deploy to AWS
- Provide service URLs

**See [GITHUB_SETUP.md](GITHUB_SETUP.md) for detailed instructions.**

### 3. Manual Deployment (Alternative)

```bash
cd scripts
./deploy.sh
```

## 🧪 Testing

### Local Testing
```bash
# Start services
cd scripts && ./test-local.sh

# Test API 1
curl http://localhost:8080/api/api1

# Test API 2
curl http://localhost:8080/api/api2

# Stop services
docker stop service1 service2
```

### Production Testing
After GitHub Actions deployment completes:
```bash
# Get ALB DNS from GitHub Actions output or AWS console
export ALB_DNS="your-alb-dns.us-east-1.elb.amazonaws.com"

curl http://$ALB_DNS/api/api1
curl http://$ALB_DNS/api/api2
curl http://$ALB_DNS/api/health
```

## 📊 Monitoring

### GitHub Actions Logs
- GitHub → Actions → Click workflow run

### AWS CloudWatch Logs
```bash
aws logs tail /ecs/microservices-demo/service1 --follow
aws logs tail /ecs/microservices-demo/service2 --follow
```

### ECS Service Status
```bash
aws ecs describe-services \
  --cluster microservices-demo-cluster \
  --services service1 service2
```

## 🔄 Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes and test locally
./scripts/test-local.sh

# 3. Commit and push
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# 4. Create Pull Request on GitHub
# - GitHub Actions runs tests automatically
# - Review and merge

# 5. Merge to main
# - GitHub Actions deploys automatically to AWS
```

## 🧹 Cleanup

### Via GitHub Actions (Recommended)
1. GitHub → Actions → "Cleanup AWS Resources"
2. Run workflow
3. Type `DELETE` to confirm

### Via Command Line
```bash
cd scripts
./cleanup.sh
```

## 💰 Cost Estimate

**Monthly AWS costs (us-east-1):**
- ECS Fargate (4 tasks): ~$50-60
- Application Load Balancer: ~$22
- NAT Gateway: ~$32
- ECR Storage: ~$1
- **Total: ~$105-115/month**

**To minimize costs:**
- Delete resources when not needed (use cleanup workflow)
- Reduce to 1 task per service for testing
- Use spot instances for dev environments

## 🛠️ Technologies

- **Backend:** Spring Boot 3.2.1, Java 17
- **Containerization:** Docker, Multi-stage builds
- **AWS:** ECS Fargate, ECR, ALB, VPC, CloudWatch
- **IaC:** CloudFormation
- **CI/CD:** GitHub Actions
- **Build:** Maven 3.9.5

## 🔐 Security

- ✅ Service 2 in private subnets (no internet access)
- ✅ Security groups restrict inter-service communication
- ✅ ECR image scanning enabled
- ✅ AWS credentials stored as GitHub Secrets
- ✅ Least privilege IAM roles

## 📚 Documentation

- [GITHUB_SETUP.md](GITHUB_SETUP.md) - Complete GitHub CI/CD setup guide
- [infrastructure/](infrastructure/) - CloudFormation templates
- [scripts/](scripts/) - Deployment and testing scripts

## 🎯 Use Cases

This architecture is perfect for:
- Microservices applications
- API gateway patterns
- Private backend services
- Learning AWS ECS and CI/CD
- Production-ready containerized apps

## 🚀 Next Steps

1. **Add more features:**
   - Database integration (RDS)
   - Caching layer (ElastiCache)
   - API authentication (Cognito)
   - Rate limiting (API Gateway)

2. **Improve CI/CD:**
   - Add staging environment
   - Integration tests
   - Security scanning
   - Blue/green deployments

3. **Monitoring & Observability:**
   - CloudWatch dashboards
   - X-Ray distributed tracing
   - Custom metrics
   - Alerting

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes and test locally
4. Create Pull Request
5. GitHub Actions will run tests

## 📝 License

This is a demo project for educational purposes.

## 🆘 Troubleshooting

### GitHub Actions fails with AWS credentials error
- Verify secrets are set correctly in GitHub
- Check AWS credentials are valid

### Deployment succeeds but services not accessible
- Wait 2-3 minutes for ECS tasks to start
- Check CloudWatch logs for errors
- Verify security groups

### Local Docker build fails
- Ensure Docker Desktop is running
- Check Java 17 is available in Docker images
- Verify internet connection for Maven downloads

### ECS tasks failing
- Check CloudWatch logs
- Verify ECR images exist
- Check task definition configuration

For detailed troubleshooting, see [GITHUB_SETUP.md](GITHUB_SETUP.md).

---

**Built with ❤️ for learning microservices, Docker, AWS ECS, and CI/CD**
