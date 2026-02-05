# AWS Infrastructure Teardown Guide

Complete guide for safely tearing down all AWS resources created by this project.

## 🎯 What Gets Deleted

When you run the teardown scripts, **ALL** of the following resources will be permanently deleted:

### CloudFormation Stacks
- ✅ `microservices-demo-infra` - Main infrastructure stack
- ✅ `microservices-demo-ecr` - Container registry stack

### AWS Resources (via CloudFormation)
- ✅ **VPC Resources:**
  - VPC (10.0.0.0/16)
  - 2 Public Subnets
  - 2 Private Subnets
  - Internet Gateway
  - NAT Gateway
  - Route Tables
  - Elastic IP for NAT

- ✅ **ECS Resources:**
  - ECS Cluster (microservices-demo-cluster)
  - ECS Services (service1, service2)
  - ECS Task Definitions
  - All running ECS tasks

- ✅ **Load Balancer:**
  - Application Load Balancer
  - Target Groups
  - Listener Rules

- ✅ **Security Groups:**
  - ALB Security Group
  - Service 1 Security Group
  - Service 2 Security Group

- ✅ **Service Discovery:**
  - Cloud Map Namespace (local)
  - Service Discovery Services

- ✅ **ECR:**
  - ECR Repository: microservices-demo/service1
  - ECR Repository: microservices-demo/service2
  - All Docker images in repositories

- ✅ **CloudWatch:**
  - Log Groups (/ecs/microservices-demo/service1)
  - Log Groups (/ecs/microservices-demo/service2)
  - All log streams

- ✅ **IAM:**
  - ECS Task Execution Roles
  - ECS Task Roles

### Cost Savings
💰 **Monthly savings: ~$107-117**

---

## 🚀 Teardown Options

You have **3 ways** to tear down your infrastructure:

### Option 1: Bash Script (Recommended)
**Best for:** Unix/Linux/Mac users

```bash
cd microservices-aws-ecs/scripts
./cleanup.sh
```

**Features:**
- ✅ Interactive with colored output
- ✅ Shows what will be deleted before confirmation
- ✅ Progress indicators
- ✅ Requires typing 'DELETE' to confirm
- ✅ Automatic verification

---

### Option 2: Python Script
**Best for:** Cross-platform, better error handling

```bash
cd microservices-aws-ecs/scripts
python3 teardown.py
```

**Features:**
- ✅ Detailed resource inventory
- ✅ Better error messages
- ✅ Resource counting
- ✅ Cross-platform compatible
- ✅ Requires typing 'DELETE' to confirm

**Requirements:**
- Python 3.6+
- boto3 library: `pip install boto3`

---

### Option 3: GitHub Actions Workflow
**Best for:** Remote execution, audit trail

**Steps:**
1. Go to GitHub: https://github.com/rajpappala/microservices-aws-ecs-claude/actions
2. Click on **"Cleanup AWS Resources"** workflow
3. Click **"Run workflow"**
4. Type `DELETE` in the confirmation box
5. Click **"Run workflow"** button

**Features:**
- ✅ Runs remotely (no local setup needed)
- ✅ Full audit trail in GitHub
- ✅ Can be run from any device
- ✅ Logged execution history

---

## 📋 Step-by-Step Teardown Process

### Pre-Teardown Checklist

Before running teardown, verify:

1. **Check what's deployed:**
   ```bash
   aws cloudformation list-stacks \
     --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
     --region us-east-1 \
     --query "StackSummaries[?contains(StackName, 'microservices-demo')]" \
     --output table
   ```

2. **Check running services:**
   ```bash
   aws ecs list-services \
     --cluster microservices-demo-cluster \
     --region us-east-1
   ```

3. **Check ECR images:**
   ```bash
   aws ecr describe-repositories \
     --region us-east-1 \
     --query "repositories[?contains(repositoryName, 'microservices-demo')]"
   ```

---

### Teardown Execution (Bash Script)

1. **Navigate to scripts directory:**
   ```bash
   cd microservices-aws-ecs/scripts
   ```

2. **Run cleanup script:**
   ```bash
   ./cleanup.sh
   ```

3. **Review resources to be deleted:**
   The script will display:
   - CloudFormation stacks
   - ECS resources
   - VPC and networking
   - ECR repositories
   - Estimated cost savings

4. **Confirm deletion:**
   - Type `DELETE` (must be uppercase)
   - Press Enter

5. **Wait for completion:**
   - Infrastructure stack: 5-10 minutes
   - ECR images: 1 minute
   - ECR stack: 1-2 minutes

6. **Verify deletion:**
   ```bash
   aws cloudformation list-stacks \
     --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
     --region us-east-1 \
     --query "StackSummaries[?contains(StackName, 'microservices-demo')]"
   ```

---

### Teardown Execution (Python Script)

1. **Install boto3 (if not installed):**
   ```bash
   pip install boto3
   ```

2. **Navigate to scripts directory:**
   ```bash
   cd microservices-aws-ecs/scripts
   ```

3. **Make script executable:**
   ```bash
   chmod +x teardown.py
   ```

4. **Run teardown script:**
   ```bash
   python3 teardown.py
   ```

5. **Follow prompts:**
   - Review resources
   - Type `DELETE` to confirm
   - Wait for completion

---

## 🕐 Timeline

### What to Expect

| Stage | Duration | Description |
|-------|----------|-------------|
| **Scanning Resources** | 10-30 seconds | Inventorying all resources |
| **Deleting ECS Services** | 2-3 minutes | Draining connections, stopping tasks |
| **Deleting Load Balancer** | 2-3 minutes | Deregistering targets, cleaning up |
| **Deleting NAT Gateway** | 1-2 minutes | Releasing Elastic IP |
| **Deleting VPC** | 1-2 minutes | Removing subnets, route tables |
| **Deleting ECR Images** | 30 seconds | Removing Docker images |
| **Deleting ECR Repos** | 30 seconds | Removing repositories |
| **Total** | **~10-15 minutes** | Full teardown |

---

## ✅ Verification

### After teardown completes, verify all resources are deleted:

**1. Check CloudFormation stacks:**
```bash
aws cloudformation list-stacks \
  --region us-east-1 \
  --query "StackSummaries[?contains(StackName, 'microservices-demo')]"
```
Expected output: Empty list or stacks with status `DELETE_COMPLETE`

**2. Check ECS cluster:**
```bash
aws ecs describe-clusters \
  --clusters microservices-demo-cluster \
  --region us-east-1
```
Expected output: Cluster not found or status `INACTIVE`

**3. Check Load Balancer:**
```bash
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query "LoadBalancers[?contains(LoadBalancerName, 'microservices-demo')]"
```
Expected output: Empty list

**4. Check ECR repositories:**
```bash
aws ecr describe-repositories \
  --region us-east-1 \
  --query "repositories[?contains(repositoryName, 'microservices-demo')]"
```
Expected output: Empty list

**5. Check VPC:**
```bash
aws ec2 describe-vpcs \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=microservices-demo-VPC"
```
Expected output: Empty list

---

## 🔧 Troubleshooting

### Issue: Stack deletion fails

**Symptoms:**
- CloudFormation stack stuck in `DELETE_IN_PROGRESS`
- Error: "Resource is being used by another resource"

**Solution:**
1. Go to AWS Console → CloudFormation
2. Click on the stuck stack
3. Go to "Events" tab to see which resource is stuck
4. Manually delete the blocking resource in AWS Console
5. Retry deletion:
   ```bash
   aws cloudformation delete-stack \
     --stack-name microservices-demo-infra \
     --region us-east-1
   ```

---

### Issue: NAT Gateway won't delete

**Symptoms:**
- NAT Gateway deletion takes > 10 minutes
- Stack stuck waiting for NAT Gateway

**Solution:**
1. Check NAT Gateway status:
   ```bash
   aws ec2 describe-nat-gateways \
     --region us-east-1 \
     --filter "Name=tag:Name,Values=*microservices-demo*"
   ```

2. If still exists, force delete:
   ```bash
   aws ec2 delete-nat-gateway \
     --nat-gateway-id nat-xxxxx \
     --region us-east-1
   ```

---

### Issue: ECR images won't delete

**Symptoms:**
- Error: "ImageReferencedByManifestList"
- Images stuck in repository

**Solution:**
1. Delete all images (including manifests):
   ```bash
   aws ecr batch-delete-image \
     --repository-name microservices-demo/service1 \
     --image-ids "$(aws ecr list-images --repository-name microservices-demo/service1 --query 'imageIds[*]' --output json)" \
     --region us-east-1
   ```

2. Force delete repository:
   ```bash
   aws ecr delete-repository \
     --repository-name microservices-demo/service1 \
     --force \
     --region us-east-1
   ```

---

### Issue: VPC won't delete

**Symptoms:**
- Error: "has dependencies and cannot be deleted"
- Network interfaces still attached

**Solution:**
1. Find attached network interfaces:
   ```bash
   aws ec2 describe-network-interfaces \
     --filters "Name=vpc-id,Values=vpc-xxxxx" \
     --region us-east-1
   ```

2. Delete each network interface:
   ```bash
   aws ec2 delete-network-interface \
     --network-interface-id eni-xxxxx \
     --region us-east-1
   ```

3. Retry VPC deletion

---

### Issue: Permission denied

**Symptoms:**
- Error: "User is not authorized to perform: cloudformation:DeleteStack"

**Solution:**
- Ensure your AWS user has required permissions
- Check IAM policies are attached to BuildUser
- See GITHUB_SETUP.md for required permissions

---

## 🔒 Safety Features

All teardown scripts include:

✅ **Pre-flight checks** - Inventory resources before deletion
✅ **Confirmation required** - Must type 'DELETE' to proceed
✅ **Progress indicators** - Real-time status updates
✅ **Error handling** - Graceful handling of missing resources
✅ **Verification** - Post-deletion checks
✅ **Detailed logging** - Full audit trail

---

## 💡 Best Practices

### Before Teardown:
1. ✅ **Backup any important data** (though this demo has no persistent data)
2. ✅ **Note your service URLs** if you need to reference them later
3. ✅ **Export CloudWatch logs** if you need them for analysis
4. ✅ **Take screenshots** of CloudFormation outputs

### After Teardown:
1. ✅ **Verify all resources deleted** using verification commands
2. ✅ **Check AWS Cost Explorer** after 24 hours to confirm $0 charges
3. ✅ **Remove AWS credentials** from GitHub Secrets if not redeploying
4. ✅ **Keep local code** - you can always redeploy

---

## 🔄 Redeployment

### If you want to redeploy after teardown:

**Option 1: Via GitHub Actions**
```bash
git commit --allow-empty -m "Redeploy infrastructure"
git push origin main
```

**Option 2: Via manual deployment**
```bash
cd microservices-aws-ecs/scripts
./deploy.sh
```

**Note:** Redeployment will create fresh resources with **new URLs**.

---

## 📊 Cost Tracking

### Monitor costs during teardown:

1. **AWS Cost Explorer:**
   - https://console.aws.amazon.com/cost-management/home

2. **Daily costs:**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2026-02-01,End=2026-02-06 \
     --granularity DAILY \
     --metrics BlendedCost
   ```

3. **Expected savings:**
   - Immediate: ECS Fargate stops (~$50-60/month)
   - Immediate: ALB stops (~$22/month)
   - Immediate: NAT Gateway stops (~$32/month)
   - **Total: ~$107-117/month**

---

## 🆘 Emergency Teardown

If normal teardown fails, use this **nuclear option**:

⚠️ **WARNING: This force-deletes everything without confirmation!**

```bash
# Delete all stacks (bypass deletion protection)
for stack in microservices-demo-infra microservices-demo-ecr; do
  aws cloudformation delete-stack --stack-name $stack --region us-east-1
done

# Force delete ECR repositories
for repo in microservices-demo/service1 microservices-demo/service2; do
  aws ecr delete-repository --repository-name $repo --force --region us-east-1
done

# Find and delete VPC by tag
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=*microservices-demo*" \
  --query "Vpcs[0].VpcId" \
  --output text \
  --region us-east-1)

if [ "$VPC_ID" != "None" ]; then
  aws ec2 delete-vpc --vpc-id $VPC_ID --region us-east-1
fi
```

---

## 📞 Support

If you encounter issues during teardown:

1. **Check AWS Console** for error messages
2. **Review CloudFormation Events** for specific failures
3. **Check GITHUB_SETUP.md** for permissions
4. **Open GitHub Issue** with error details

---

## 📝 Teardown Checklist

Before marking teardown complete, verify:

- [ ] CloudFormation stacks deleted
- [ ] ECS cluster deleted
- [ ] Load Balancer deleted
- [ ] VPC deleted
- [ ] NAT Gateway deleted
- [ ] ECR repositories deleted
- [ ] Security Groups deleted
- [ ] CloudWatch Log Groups deleted (or scheduled for deletion)
- [ ] No remaining costs in AWS Cost Explorer
- [ ] AWS credentials removed from GitHub (if not redeploying)

---

**Remember:** You can always redeploy! The infrastructure is fully automated. 🚀
