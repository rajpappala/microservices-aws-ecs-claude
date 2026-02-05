# GitHub CI/CD Setup Guide

This guide will help you set up automated deployment to AWS using GitHub Actions.

## Architecture

```
GitHub Push → GitHub Actions → Build & Test → Push to ECR → Deploy to ECS
```

## Prerequisites

1. GitHub account
2. AWS account with credentials
3. Local Docker running (for testing)

---

## Step 1: Create GitHub Repository

### Option A: Using GitHub CLI
```bash
cd microservices-aws-ecs
gh repo create microservices-aws-ecs --public --source=. --remote=origin --push
```

### Option B: Using GitHub Web UI
1. Go to https://github.com/new
2. Repository name: `microservices-aws-ecs`
3. Choose Public or Private
4. **Do NOT** initialize with README (we already have files)
5. Click "Create repository"

Then push your code:
```bash
cd microservices-aws-ecs
git init
git add .
git commit -m "Initial commit: Spring Boot microservices with AWS ECS deployment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/microservices-aws-ecs.git
git push -u origin main
```

---

## Step 2: Configure AWS Credentials in GitHub

### 2.1 Get AWS Credentials
You already have these configured locally. To view them:
```bash
cat ~/.aws/credentials
```

You'll see:
```
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

### 2.2 Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these two secrets:

**Secret 1:**
- Name: `AWS_ACCESS_KEY_ID`
- Value: Your AWS Access Key ID

**Secret 2:**
- Name: `AWS_SECRET_ACCESS_KEY`
- Value: Your AWS Secret Access Key

---

## Step 3: GitHub Actions Workflows

We've created 3 workflows:

### 1. **Main Deployment** (`.github/workflows/deploy.yml`)
**Triggers:** Push to `main` branch

**What it does:**
1. ✅ Builds and tests both services
2. ✅ Creates ECR repositories (if not exists)
3. ✅ Builds Docker images
4. ✅ Pushes images to ECR
5. ✅ Deploys infrastructure using CloudFormation
6. ✅ Updates ECS services
7. ✅ Verifies deployment

**Workflow stages:**
```
build-and-test → deploy-infrastructure → build-and-push-docker → deploy-to-ecs → notify
```

### 2. **Pull Request Check** (`.github/workflows/pr-check.yml`)
**Triggers:** Pull request to `main` or `develop`

**What it does:**
- Builds and tests code
- Validates Docker builds
- Does NOT deploy to AWS

### 3. **Cleanup** (`.github/workflows/cleanup.yml`)
**Triggers:** Manual (workflow_dispatch)

**What it does:**
- Deletes all AWS resources
- Must type "DELETE" to confirm

---

## Step 4: First Deployment

### Push to GitHub and Trigger Deployment

```bash
cd microservices-aws-ecs
git add .
git commit -m "Add GitHub Actions CI/CD pipeline"
git push origin main
```

### Monitor the Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. You'll see the workflow running
4. Click on the workflow to see detailed logs

**Deployment takes ~10-15 minutes**

### Get Your Service URLs

After deployment completes:
1. Go to the workflow run
2. Click on the **deploy-to-ecs** job
3. Scroll to bottom - you'll see:
   ```
   Your services are available at:
   - API 1: http://your-alb-dns.us-east-1.elb.amazonaws.com/api/api1
   - API 2: http://your-alb-dns.us-east-1.elb.amazonaws.com/api/api2
   - Health: http://your-alb-dns.us-east-1.elb.amazonaws.com/api/health
   ```

---

## Step 5: Test the CI/CD Pipeline

### Make a Code Change

1. Edit a file (e.g., update a message in Service 2):
```bash
# Edit service2/src/main/java/com/example/service2/controller/BackendController.java
# Change a message string
```

2. Commit and push:
```bash
git add .
git commit -m "Update API response message"
git push origin main
```

3. Watch GitHub Actions automatically:
   - Build the new code
   - Create new Docker images
   - Deploy to AWS
   - Verify deployment

---

## CI/CD Pipeline Features

### Automatic Triggers
- ✅ **Every push to main** → Full deployment
- ✅ **Pull requests** → Build and test only
- ✅ **Manual trigger** → Deploy or cleanup

### Safety Features
- ✅ Tests run before deployment
- ✅ Deployment only on successful tests
- ✅ Health checks after deployment
- ✅ Automatic rollback on failure

### Image Management
- ✅ Images tagged with git commit SHA
- ✅ `latest` tag always points to newest
- ✅ Easy rollback to previous versions

---

## Step 6: Working with Branches

### Development Workflow

```bash
# Create feature branch
git checkout -b feature/new-endpoint

# Make changes
# ... edit code ...

# Commit changes
git add .
git commit -m "Add new endpoint"

# Push to GitHub
git push origin feature/new-endpoint

# Create Pull Request on GitHub
# - GitHub Actions will run tests automatically
# - Review the PR
# - Merge to main when ready
# - Main branch deployment triggers automatically
```

---

## Workflow Customization

### Change AWS Region

Edit `.github/workflows/deploy.yml`:
```yaml
env:
  AWS_REGION: us-west-2  # Change this
  ENVIRONMENT_NAME: microservices-demo
```

### Change Environment Name

Edit `.github/workflows/deploy.yml`:
```yaml
env:
  AWS_REGION: us-east-1
  ENVIRONMENT_NAME: my-production-env  # Change this
```

### Add Manual Approval for Production

Edit `.github/workflows/deploy.yml` and add before `deploy-to-ecs` job:
```yaml
  approve-deployment:
    name: Approve Deployment
    runs-on: ubuntu-latest
    needs: build-and-push-docker
    environment: production  # Requires manual approval
    steps:
      - name: Waiting for approval
        run: echo "Deployment approved!"
```

Then in GitHub:
1. Settings → Environments → New environment
2. Name: `production`
3. Check "Required reviewers"
4. Add reviewers

---

## Monitoring and Logs

### View GitHub Actions Logs
- GitHub → Actions → Click on workflow run

### View AWS ECS Logs
```bash
# Service 1 logs
aws logs tail /ecs/microservices-demo/service1 --follow

# Service 2 logs
aws logs tail /ecs/microservices-demo/service2 --follow
```

### View Deployment Status
```bash
aws ecs describe-services \
  --cluster microservices-demo-cluster \
  --services service1 service2 \
  --region us-east-1
```

---

## Rollback Procedure

### Option 1: Rollback via Git
```bash
# Find the commit you want to rollback to
git log --oneline

# Create revert commit
git revert HEAD
git push origin main

# GitHub Actions will deploy the previous version
```

### Option 2: Manual ECS Rollback
```bash
# List task definitions
aws ecs list-task-definitions \
  --family-prefix microservices-demo-service1 \
  --region us-east-1

# Update service to previous task definition
aws ecs update-service \
  --cluster microservices-demo-cluster \
  --service service1 \
  --task-definition microservices-demo-service1:PREVIOUS_VERSION \
  --region us-east-1
```

---

## Cleanup All Resources

### Via GitHub Actions (Recommended)
1. Go to GitHub → Actions
2. Click on "Cleanup AWS Resources" workflow
3. Click "Run workflow"
4. Type `DELETE` to confirm
5. Click "Run workflow"

### Via Command Line
```bash
cd microservices-aws-ecs/scripts
./cleanup.sh
```

---

## Cost Management

### Estimated Monthly Costs
- ECS Fargate (4 tasks): ~$50-60
- Application Load Balancer: ~$22
- NAT Gateway: ~$32
- **Total: ~$104-115/month**

### To Minimize Costs:
1. Delete when not in use (use cleanup workflow)
2. Reduce to 1 task per service for testing
3. Use AWS Free Tier eligible services where possible

---

## Troubleshooting

### Workflow Fails: "AWS credentials not configured"
- Check GitHub Secrets are correctly set
- Verify AWS credentials are valid

### Workflow Fails: "ECR image not found"
- Check ECR repositories were created
- Verify Docker build succeeded

### Deployment Succeeds but Services Not Accessible
- Wait 2-3 minutes for tasks to start
- Check ECS task health in AWS console
- View CloudWatch logs for errors

### Services Running but API Returns 503
- Tasks may still be starting (wait 2-3 minutes)
- Check target group health in AWS console
- Verify security groups allow traffic

---

## Next Steps

1. ✅ **Set up branch protection rules**
   - Require PR reviews before merging
   - Require status checks to pass

2. ✅ **Add more environments**
   - Create `develop` branch for staging
   - Create separate AWS accounts for dev/prod

3. ✅ **Add monitoring**
   - Set up CloudWatch alarms
   - Integrate with Slack/email notifications

4. ✅ **Add security scanning**
   - Use Snyk or Dependabot for dependency scanning
   - Scan Docker images for vulnerabilities

5. ✅ **Add integration tests**
   - Test inter-service communication
   - Test against deployed environment

---

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## Support

If you encounter issues:
1. Check GitHub Actions logs
2. Check AWS CloudWatch logs
3. Review CloudFormation events in AWS console
4. Check ECS service events

For questions, create an issue in the repository.
