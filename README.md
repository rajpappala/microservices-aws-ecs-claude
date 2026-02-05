# Microservices on AWS ECS with GitHub Actions CI/CD

Enterprise-grade microservices solution with Spring Boot, Docker, AWS ECS Fargate, and fully automated CI/CD pipeline using GitHub Actions.

## 🚀 Features

- ✅ 2 Spring Boot microservices (Java 17)
- ✅ Service-to-service communication
- ✅ Docker containerization with multi-stage builds
- ✅ AWS ECS Fargate deployment (serverless containers)
- ✅ Private networking for backend service
- ✅ Application Load Balancer with health checks
- ✅ CloudFormation Infrastructure as Code
- ✅ **GitHub Actions CI/CD pipeline**
- ✅ Automated deployments on every commit
- ✅ Pull request validation
- ✅ High availability across multiple AZs
- ✅ Auto-scaling ready
- ✅ CloudWatch logging and monitoring

---

## 🏗️ Detailed Architecture

### Current Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                              INTERNET                               │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │ HTTPS/HTTP
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Application Load Balancer                       │
│                        (Public Subnets)                             │
│  • Health Checks  • SSL Termination  • Traffic Distribution        │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │ Target Group (Port 8080)
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              PUBLIC SUBNETS (Multi-AZ)                       │ │
│  │                                                              │ │
│  │  ┌────────────────┐        ┌────────────────┐             │ │
│  │  │   Service 1    │        │   Service 1    │             │ │
│  │  │  ECS Task 1    │        │  ECS Task 2    │             │ │
│  │  │  (AZ: us-e-1a) │        │  (AZ: us-e-1b) │             │ │
│  │  │                │        │                │             │ │
│  │  │  Port: 8080    │        │  Port: 8080    │             │ │
│  │  │  API Gateway   │        │  API Gateway   │             │ │
│  │  └────────┬───────┘        └────────┬───────┘             │ │
│  │           │                         │                      │ │
│  └───────────┼─────────────────────────┼──────────────────────┘ │
│              │                         │                        │
│              │   Service Discovery     │                        │
│              │   (service2.local)      │                        │
│              └────────┬────────────────┘                        │
│                       │ HTTP (Private)                          │
│                       ▼                                          │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              PRIVATE SUBNETS (Multi-AZ)                      │ │
│  │              (No Internet Access)                            │ │
│  │                                                              │ │
│  │  ┌────────────────┐        ┌────────────────┐             │ │
│  │  │   Service 2    │        │   Service 2    │             │ │
│  │  │  ECS Task 1    │        │  ECS Task 2    │             │ │
│  │  │  (AZ: us-e-1a) │        │  (AZ: us-e-1b) │             │ │
│  │  │                │        │                │             │ │
│  │  │  Port: 8080    │        │  Port: 8080    │             │ │
│  │  │  Backend API   │        │  Backend API   │             │ │
│  │  └────────────────┘        └────────────────┘             │ │
│  │                                                              │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                    NAT Gateway                               │ │
│  │         (Allows private subnets to reach ECR/Internet)       │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
        ┌─────────────────────┐   ┌─────────────────────┐
        │   Amazon ECR        │   │  CloudWatch Logs    │
        │  (Docker Images)    │   │   (Logging)         │
        └─────────────────────┘   └─────────────────────┘
```

### Component Details

#### 1. **VPC (Virtual Private Cloud)**
- **CIDR:** 10.0.0.0/16
- **Availability Zones:** 2 (us-east-1a, us-east-1b)
- **Subnets:**
  - Public Subnets: 10.0.1.0/24, 10.0.2.0/24
  - Private Subnets: 10.0.11.0/24, 10.0.12.0/24

#### 2. **Application Load Balancer (ALB)**
- **Type:** Internet-facing
- **Protocol:** HTTP (Port 80)
- **Health Check:** `/api/health`
- **Target:** Service 1 tasks
- **Features:**
  - Connection draining
  - Sticky sessions support
  - Cross-zone load balancing

#### 3. **ECS Fargate Cluster**
- **Cluster Name:** microservices-demo-cluster
- **Launch Type:** Fargate (serverless)
- **Task Count:** 2 tasks per service
- **CPU:** 0.5 vCPU per task
- **Memory:** 1 GB per task

#### 4. **Service 1 - API Gateway**
- **Location:** Public subnets
- **Tasks:** 2 (High Availability)
- **Port:** 8080
- **Endpoints:**
  - `GET /api/api1` → Calls Service 2 endpoint1
  - `GET /api/api2` → Calls Service 2 endpoint2
  - `GET /api/health` → Health check
- **Communication:** Receives public traffic from ALB
- **Features:**
  - WebClient for Service 2 calls
  - Circuit breaker ready
  - Request logging

#### 5. **Service 2 - Backend Service**
- **Location:** Private subnets (ISOLATED)
- **Tasks:** 2 (High Availability)
- **Port:** 8080
- **Endpoints:**
  - `GET /api/endpoint1` → Returns sample data
  - `GET /api/endpoint2` → Returns different sample data
  - `GET /api/health` → Health check
- **Communication:** Only accessible from Service 1
- **Security:** No public internet access

#### 6. **Service Discovery**
- **Type:** AWS Cloud Map (Private DNS)
- **Namespace:** local
- **Service Name:** service2.local
- **Purpose:** Service 1 discovers Service 2 dynamically
- **DNS Resolution:** `http://service2.local:8080`

#### 7. **Security Groups**
```
┌──────────────────────────────────────────────────┐
│ ALB Security Group                               │
│ Inbound: 0.0.0.0/0 → Port 80 (HTTP)            │
│ Outbound: Service 1 SG → Port 8080              │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ Service 1 Security Group                         │
│ Inbound: ALB SG → Port 8080                     │
│ Outbound: Service 2 SG → Port 8080              │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ Service 2 Security Group                         │
│ Inbound: Service 1 SG → Port 8080               │
│ Outbound: None (Isolated)                       │
└──────────────────────────────────────────────────┘
```

#### 8. **NAT Gateway**
- **Purpose:** Allow private subnets to pull Docker images from ECR
- **Location:** Public subnet
- **Elastic IP:** Assigned automatically
- **Usage:** Outbound internet access for private resources

#### 9. **Elastic Container Registry (ECR)**
- **Repositories:**
  - microservices-demo/service1
  - microservices-demo/service2
- **Image Scanning:** Enabled on push
- **Lifecycle Policy:** Keep last 10 images
- **Encryption:** AES-256

#### 10. **CloudWatch Logs**
- **Log Groups:**
  - /ecs/microservices-demo/service1
  - /ecs/microservices-demo/service2
- **Retention:** 7 days
- **Features:** Real-time log streaming

---

## 🔄 CI/CD Pipeline Architecture

### GitHub Actions Workflow

```
┌──────────────────────────────────────────────────────────────┐
│                    DEVELOPER WORKFLOW                        │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │ git push origin main
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                     GITHUB ACTIONS                           │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Stage 1: Build & Test                                  │ │
│  │ • Checkout code                                        │ │
│  │ • Setup JDK 17                                         │ │
│  │ • Maven build (service1 & service2)                    │ │
│  │ • Run unit tests                                       │ │
│  │ • Upload artifacts                                     │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │ Success                             │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Stage 2: Deploy Infrastructure                         │ │
│  │ • Configure AWS credentials                            │ │
│  │ • Deploy ECR repositories (CloudFormation)             │ │
│  │ • Get repository URIs                                  │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │ Success                             │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Stage 3: Build & Push Docker Images                    │ │
│  │ • Login to ECR                                         │ │
│  │ • Build service1 Docker image                          │ │
│  │ • Build service2 Docker image                          │ │
│  │ • Tag images (git SHA + latest)                        │ │
│  │ • Push to ECR                                          │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │ Success                             │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Stage 4: Deploy to ECS                                 │ │
│  │ • Deploy CloudFormation stack                          │ │
│  │   - VPC & Networking                                   │ │
│  │   - Security Groups                                    │ │
│  │   - Load Balancer                                      │ │
│  │   - ECS Cluster & Services                             │ │
│  │   - Task Definitions                                   │ │
│  │   - Service Discovery                                  │ │
│  │ • Wait for services to stabilize                       │ │
│  │ • Health check verification                            │ │
│  │ • Output service URLs                                  │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │ Success                             │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Stage 5: Notify                                        │ │
│  │ • Deployment summary                                   │ │
│  │ • Service URLs                                         │ │
│  │ • GitHub job summary                                   │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                         │
                         │ Deployed Successfully
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                     AWS PRODUCTION                           │
│              Services Running on ECS                         │
└──────────────────────────────────────────────────────────────┘
```

**Pipeline Duration:** ~10-15 minutes

---

## 📋 Architecture Characteristics

### High Availability
- ✅ Multi-AZ deployment (2 availability zones)
- ✅ Multiple tasks per service (2 tasks minimum)
- ✅ Load balancer health checks
- ✅ Automatic task replacement on failure

### Security
- ✅ **Private networking** - Service 2 has no internet access
- ✅ **Security groups** - Least privilege access
- ✅ **IAM roles** - Service-level permissions
- ✅ **VPC isolation** - Network segmentation
- ✅ **Image scanning** - Vulnerability detection in ECR
- ✅ **Secrets management** - GitHub Secrets for credentials

### Scalability
- ✅ **Horizontal scaling** - Add more ECS tasks
- ✅ **Auto-scaling ready** - Can configure target tracking
- ✅ **Stateless services** - Easy to scale
- ✅ **Load balancing** - Traffic distribution

### Observability
- ✅ **CloudWatch Logs** - Centralized logging
- ✅ **Health checks** - Automated monitoring
- ✅ **ECS metrics** - CPU, memory, network
- ✅ **ALB metrics** - Request count, latency
- ✅ **GitHub Actions logs** - Deployment tracking

### Cost Optimization
- ✅ **Fargate** - Pay only for what you use
- ✅ **NAT Gateway** - Single gateway for cost savings
- ✅ **ECR lifecycle** - Automatic old image cleanup
- ✅ **Log retention** - 7 days to reduce storage costs

---

## 🚀 Service Details

### Service 1 - API Gateway Service

**Technology Stack:**
- Spring Boot 3.2.1
- Spring WebFlux (for Service 2 calls)
- Spring Actuator (health checks)

**Endpoints:**
```
GET /api/api1
  └─→ Calls Service 2 /api/endpoint1
  └─→ Aggregates response
  └─→ Returns JSON with Service 2 data

GET /api/api2
  └─→ Calls Service 2 /api/endpoint2
  └─→ Aggregates response
  └─→ Returns JSON with Service 2 data

GET /api/health
  └─→ Returns health status
  └─→ Used by ALB health checks
```

**Configuration:**
```properties
server.port=8080
service2.url=http://service2.local:8080
```

**Docker Image Size:** ~200 MB (compressed)

---

### Service 2 - Backend Service

**Technology Stack:**
- Spring Boot 3.2.1
- Spring Web MVC
- Spring Actuator (health checks)

**Endpoints:**
```
GET /api/endpoint1
  └─→ Returns sample data (ID: 1)
  └─→ Includes timestamp
  └─→ JSON response

GET /api/endpoint2
  └─→ Returns different sample data (ID: 2)
  └─→ Includes timestamp
  └─→ JSON response

GET /api/health
  └─→ Returns health status
  └─→ Used by ECS health checks
```

**Configuration:**
```properties
server.port=8080
```

**Docker Image Size:** ~180 MB (compressed)

---

## 📁 Project Structure

```
microservices-aws-ecs/
├── .github/
│   └── workflows/
│       ├── deploy.yml          # Main CI/CD pipeline
│       ├── pr-check.yml        # PR validation
│       └── cleanup.yml         # Resource cleanup
│
├── service1/                   # Service 1 (API Gateway)
│   ├── src/
│   │   └── main/
│   │       ├── java/com/example/service1/
│   │       │   ├── Service1Application.java      # Main app
│   │       │   ├── controller/
│   │       │   │   └── GatewayController.java    # REST endpoints
│   │       │   └── service/
│   │       │       └── Service2Client.java       # Service 2 client
│   │       └── resources/
│   │           └── application.properties        # Configuration
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── .dockerignore
│   └── pom.xml                 # Maven dependencies
│
├── service2/                   # Service 2 (Backend)
│   ├── src/
│   │   └── main/
│   │       ├── java/com/example/service2/
│   │       │   ├── Service2Application.java      # Main app
│   │       │   └── controller/
│   │       │       └── BackendController.java    # REST endpoints
│   │       └── resources/
│   │           └── application.properties        # Configuration
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── .dockerignore
│   └── pom.xml                 # Maven dependencies
│
├── infrastructure/             # CloudFormation templates
│   ├── ecr-repositories.yaml   # ECR repositories
│   ├── cloudformation-stack.yaml # Main infrastructure
│   └── builduser-policy.json   # IAM policy example
│
├── scripts/                    # Deployment scripts
│   ├── deploy.sh               # Deploy to AWS
│   ├── cleanup.sh              # Remove all resources
│   └── test-local.sh           # Test locally with Docker
│
├── .gitignore                  # Git ignore rules
├── GITHUB_SETUP.md            # GitHub CI/CD setup guide
└── README.md                   # This file
```

---

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

---

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

---

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

### CloudWatch Metrics
- ECS CPU utilization
- ECS memory utilization
- ALB request count
- ALB target response time
- ALB healthy host count

---

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

---

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

---

## 💰 Cost Estimate

### Current Architecture (Monthly - us-east-1)

| Component | Details | Cost |
|-----------|---------|------|
| **ECS Fargate** | 4 tasks × 0.5 vCPU × 1GB RAM | ~$50-60 |
| **Application Load Balancer** | 1 ALB + data transfer | ~$22 |
| **NAT Gateway** | 1 NAT × data processing | ~$32 |
| **ECR Storage** | Image storage (~2GB) | ~$1 |
| **CloudWatch Logs** | 7 days retention | ~$2 |
| **Data Transfer** | Outbound traffic | Variable |
| **Total** | | **~$107-117/month** |

### Cost Optimization Tips
- ✅ Delete resources when not in use (cleanup workflow)
- ✅ Reduce to 1 task per service for development
- ✅ Use smaller task sizes (0.25 vCPU) for testing
- ✅ Implement auto-scaling to scale down during off-hours
- ✅ Use S3 lifecycle policies for ECR cleanup

---

## 🛠️ Technologies

### Backend
- **Framework:** Spring Boot 3.2.1
- **Language:** Java 17
- **Build Tool:** Maven 3.9.5
- **Dependencies:** Spring Web, Spring WebFlux, Spring Actuator

### Infrastructure
- **Container Orchestration:** Amazon ECS Fargate
- **Container Registry:** Amazon ECR
- **Load Balancer:** Application Load Balancer (ALB)
- **Networking:** Amazon VPC, NAT Gateway
- **Service Discovery:** AWS Cloud Map
- **Logging:** Amazon CloudWatch Logs
- **IaC:** AWS CloudFormation

### CI/CD
- **Version Control:** Git, GitHub
- **Pipeline:** GitHub Actions
- **Deployment:** Automated on push to main

### Containerization
- **Runtime:** Docker
- **Build Strategy:** Multi-stage builds
- **Base Images:** Eclipse Temurin 17

---

## 🔐 Security

### Network Security
- ✅ **Private Subnets** - Service 2 isolated from internet
- ✅ **Security Groups** - Least privilege access controls
- ✅ **NAT Gateway** - Controlled outbound access for private subnets
- ✅ **VPC Isolation** - Network segmentation

### Application Security
- ✅ **Image Scanning** - ECR vulnerability scanning
- ✅ **IAM Roles** - Task-level permissions
- ✅ **Secrets Management** - GitHub Secrets for AWS credentials
- ✅ **Health Checks** - Automated failure detection

### CI/CD Security
- ✅ **Branch Protection** - Main branch protected
- ✅ **Pull Request Reviews** - Code review before merge
- ✅ **Automated Testing** - Tests run before deployment
- ✅ **Credential Rotation** - Support for AWS credential rotation

---

## 📚 Documentation

- **[GITHUB_SETUP.md](GITHUB_SETUP.md)** - Complete GitHub CI/CD setup guide
- **[infrastructure/](infrastructure/)** - CloudFormation templates
- **[scripts/](scripts/)** - Deployment and testing scripts

---

## 🚀 Future Enhancements (Roadmap)

### Phase 1: Security & Domain (High Priority)
1. **Route 53 + Custom Domain**
   - Register custom domain (e.g., api.yourdomain.com)
   - Create Route 53 hosted zone
   - SSL/TLS certificates via AWS Certificate Manager (ACM)
   - HTTPS termination at ALB
   - **Benefits:** Professional URLs, encrypted traffic, SEO
   - **Cost:** ~$1/month (Route 53) + domain registration

2. **OAuth 2.0 Authentication**
   - Implement AWS Cognito User Pools
   - JWT token-based authentication
   - User registration and login flows
   - Secure service-to-service communication
   - **Benefits:** User management, secure APIs, industry standard
   - **Cost:** Free tier covers most use cases

3. **API Gateway Integration**
   - Add AWS API Gateway in front of ALB
   - Request/response transformation
   - Rate limiting and throttling
   - API keys and usage plans
   - Request validation
   - **Benefits:** API management, security, monitoring
   - **Cost:** ~$3-10/month (based on API calls)

### Phase 2: Performance & Scalability (Medium Priority)
4. **ECS Service Auto Scaling**
   - Target tracking scaling policies
   - Scale based on CPU/Memory utilization
   - Scale based on ALB request count
   - Scheduled scaling for predictable traffic
   - Min tasks: 2, Max tasks: 10
   - **Benefits:** Cost optimization, handle traffic spikes
   - **Cost:** Pay only for running tasks

5. **RDS Database Integration**
   - Add Amazon RDS (PostgreSQL/MySQL)
   - Multi-AZ for high availability
   - Automated backups
   - Spring Data JPA integration
   - **Benefits:** Data persistence, ACID compliance
   - **Cost:** ~$15-30/month (db.t3.micro)

6. **Redis Cache (ElastiCache)**
   - Amazon ElastiCache for Redis
   - Cache frequently accessed data
   - Session storage
   - Reduce database load
   - **Benefits:** Faster response times, reduced costs
   - **Cost:** ~$12-15/month (cache.t3.micro)

### Phase 3: Observability & Reliability (Medium Priority)
7. **Enhanced Monitoring**
   - CloudWatch Dashboards
   - AWS X-Ray distributed tracing
   - Custom CloudWatch metrics
   - SNS alerts for critical events
   - **Benefits:** Better visibility, faster troubleshooting
   - **Cost:** ~$5-10/month

8. **Message Queue (SQS/SNS)**
   - Amazon SQS for asynchronous processing
   - Amazon SNS for pub/sub notifications
   - Decouple services
   - Email/SMS notifications
   - **Benefits:** Resilience, async processing
   - **Cost:** Minimal (free tier covers most)

### Phase 4: Advanced Features (Lower Priority)
9. **Blue/Green Deployments**
   - Zero-downtime deployments
   - ECS deployment circuit breaker
   - Automated rollback on failures
   - **Benefits:** Safe deployments, instant rollback

10. **Multi-Region Deployment**
    - Deploy to multiple AWS regions
    - Route 53 geolocation routing
    - Cross-region replication
    - **Benefits:** Global reach, disaster recovery
    - **Cost:** ~2x current infrastructure cost

11. **WAF (Web Application Firewall)**
    - AWS WAF on ALB
    - SQL injection protection
    - XSS attack prevention
    - DDoS protection
    - **Benefits:** Enhanced security
    - **Cost:** ~$5-10/month

12. **Service Mesh (AWS App Mesh)**
    - Traffic management
    - Service-to-service encryption (mTLS)
    - Circuit breakers and retries
    - Observability
    - **Benefits:** Advanced microservices features
    - **Cost:** Minimal overhead

---

### Implementation Priority

**Month 1:**
- ✅ Route 53 + Custom Domain + HTTPS
- ✅ OAuth 2.0 Authentication (Cognito)

**Month 2:**
- ✅ API Gateway Integration
- ✅ ECS Auto Scaling
- ✅ CloudWatch Dashboards

**Month 3:**
- ✅ RDS Database
- ✅ Redis Cache
- ✅ Enhanced Monitoring (X-Ray)

**Month 4+:**
- ✅ Message Queues (SQS/SNS)
- ✅ Blue/Green Deployments
- ✅ WAF Integration

---

## 🎯 Use Cases

This architecture is perfect for:
- ✅ **Microservices applications** - Scalable, independent services
- ✅ **API gateway patterns** - Public API with private backend
- ✅ **Private backend services** - Secure internal services
- ✅ **Learning AWS ECS and CI/CD** - Real-world example
- ✅ **Production-ready containerized apps** - Enterprise-grade setup
- ✅ **SaaS applications** - Multi-tenant ready
- ✅ **Mobile/Web backends** - RESTful APIs
- ✅ **B2B integrations** - API-first approach

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test locally
4. Commit changes (`git commit -m 'Add amazing feature'`)
5. Push to branch (`git push origin feature/amazing-feature`)
6. Create Pull Request
7. GitHub Actions will run tests automatically

---

## 📝 License

This is a demo project for educational purposes.

---

## 🆘 Troubleshooting

### GitHub Actions fails with AWS credentials error
**Solution:**
- Verify secrets are set correctly in GitHub Settings
- Check AWS credentials are valid: `aws sts get-caller-identity`
- Ensure IAM user has required permissions

### Deployment succeeds but services not accessible
**Solution:**
- Wait 2-3 minutes for ECS tasks to start
- Check CloudWatch logs: `aws logs tail /ecs/microservices-demo/service1 --follow`
- Verify security groups allow traffic
- Check target group health in AWS Console

### Local Docker build fails
**Solution:**
- Ensure Docker Desktop is running
- Check Java 17 is available in Docker images
- Verify internet connection for Maven downloads
- Clear Docker cache: `docker system prune -a`

### ECS tasks failing to start
**Solution:**
- Check CloudWatch logs for errors
- Verify ECR images exist and are pushed correctly
- Check task definition CPU/memory limits
- Ensure IAM task execution role has ECR pull permissions

### Service 2 not reachable from Service 1
**Solution:**
- Verify Service Discovery is configured (service2.local)
- Check security group allows traffic from Service 1 to Service 2
- Ensure Service 2 tasks are running: `aws ecs list-tasks --cluster microservices-demo-cluster`
- Check Service 1 logs for connection errors

### High AWS costs
**Solution:**
- Review CloudWatch metrics for usage patterns
- Reduce number of tasks to 1 per service for development
- Delete resources when not in use (cleanup.sh)
- Implement auto-scaling to scale down during off-hours
- Use AWS Cost Explorer to identify cost drivers

For detailed troubleshooting, see [GITHUB_SETUP.md](GITHUB_SETUP.md).

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/rajpappala/microservices-aws-ecs-claude/issues)
- **Discussions:** [GitHub Discussions](https://github.com/rajpappala/microservices-aws-ecs-claude/discussions)
- **Documentation:** This README and GITHUB_SETUP.md

---

## 🌟 Acknowledgments

Built with modern technologies and best practices for cloud-native microservices architecture.

**Technologies Used:**
- Spring Boot (VMware/Broadcom)
- Docker (Docker Inc.)
- Amazon Web Services (AWS)
- GitHub Actions (GitHub)

---

**Built with ❤️ for learning microservices, Docker, AWS ECS, and CI/CD**

**Author:** [@rajpappala](https://github.com/rajpappala)
**Repository:** [microservices-aws-ecs-claude](https://github.com/rajpappala/microservices-aws-ecs-claude)
