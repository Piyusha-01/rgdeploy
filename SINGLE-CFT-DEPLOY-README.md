# Research Gateway Single-CFT Deployment Guide

This guide describes how to deploy the Research Gateway application using the new single-stack CloudFormation approach. All AWS resources (ALB, Cognito, DocumentDB, EC2, etc.) are provisioned in one unified stack, and the EC2 instance configures itself automatically using stack outputs.

---

## Overview

- **Single CFT**: All AWS resources are created by a single CloudFormation template (`rgdeploy-cft.yml`).
- **Automated Configuration**: The EC2 instance generates its configuration at launch using `makeconfigs.sh`, with parameters derived from stack outputs.
- **Wrapper Script**: The `rgdeploy.sh` script wraps the deployment, handling parameter passing and stack creation.

---

## Prerequisites

1. **AWS Account** with sufficient permissions to create VPC, EC2, IAM, Cognito, DocumentDB, S3, and related resources.
2. **VPC and Subnets**: You must have an existing VPC with at least 3 public and 3 private subnets.
3. **ACM Certificate** (optional): For SSL, create or import a certificate in AWS Certificate Manager.
4. **AWS CLI**: Installed and configured (`aws configure`).
5. **jq**: Installed on your local machine and available in the EC2 AMI.
6. **S3 Bucket**: A bucket to store deployment scripts and configuration files.
7. **Scripts**: Ensure the following files are uploaded to your S3 bucket:
    - `makeconfigs.sh`
    - `updatescripts.sh`
    - Any other scripts referenced in UserData or by the application
8. **CloudFormation Template**: `rgdeploy-cft.yml` must be present in your working directory.

---

## Preparation

1. **Upload Scripts to S3**

   ```bash
   aws s3 cp makeconfigs.sh s3://<your-bucket>/
   aws s3 cp updatescripts.sh s3://<your-bucket>/
   # Upload any other required scripts
   ```

2. **Prepare Parameters**

   Gather the following information:
   - AMI ID for the EC2 instance (with required software pre-installed)
   - S3 bucket name
   - VPC ID
   - Public and private subnet IDs (3 each)
   - EC2 Key Pair name
   - Deployment environment (DEV, QA, STAGE, PROD)
   - Research Gateway URL (e.g., `https://myrg.example.com`)
   - ACM Certificate ARN (optional, for SSL)
   - Route53 Hosted Zone ID for your domain
   - AWS region

---

## Deployment Steps

1. **Run the Deployment Script**

   ```bash
   ./rgdeploy.sh \
     --ami-id <AMI_ID> \
     --bucket-name <S3_BUCKET> \
     --vpc-id <VPC_ID> \
     --public-subnet-1 <SUBNET_ID> \
     --public-subnet-2 <SUBNET_ID> \
     --public-subnet-3 <SUBNET_ID> \
     --private-subnet-1 <SUBNET_ID> \
     --private-subnet-2 <SUBNET_ID> \
     --private-subnet-3 <SUBNET_ID> \
     --keypair <KEYPAIR_NAME> \
     --env <ENV> \
     --rg-url <RG_URL> \
     --certificate-arn <CERT_ARN> \
     --region <AWS_REGION> \
     --hostedzoneid <ROUTE53_HOSTED_ZONE_ID>
   ```

   - All parameters are required except `--certificate-arn` (omit for non-SSL).
   - The script will deploy the unified stack using `rgdeploy-cft.yml`.

2. **What Happens During Deployment**

   - The CloudFormation stack provisions all AWS resources in the correct order.
   - The EC2 instance, on first boot, downloads the necessary scripts from S3.
   - It generates application configuration files by running `makeconfigs.sh`, using live stack outputs (Cognito, DocumentDB, etc.).
   - The application is started automatically.

---

## Post-Deployment

- **Access the Application**: Use the URL you provided (`--rg-url`) to access the Research Gateway portal.
- **EC2 Instance**: The instance will be running in your private subnet, registered with the ALB.
- **Cognito & DocumentDB**: User authentication and data storage are fully configured.
- **Route53**: Ensure your domain's DNS is set up to point to the ALB if using a custom domain.

---

## Troubleshooting

- **Stack Creation Fails**: Check the CloudFormation console for error messages and resource status.
- **EC2 Boot Issues**: Review the EC2 instance's system logs and `/var/log/user-data.log`.
- **Configuration Issues**: Ensure all scripts are present in S3 and the AMI includes `jq` and other dependencies.
- **SSL/Domain Issues**: Verify your ACM certificate is valid and in the correct region, and that Route53 records are correct.

---

## Tips

- **Rollback**: If the stack fails, CloudFormation will roll back all resources.
- **Re-deploy**: You can delete the stack and re-run the deployment as needed.
- **Custom AMI**: Use an AMI with all required software (docker, jq, awscli, etc.) pre-installed for smoother setup.

---

## Support

For further assistance, refer to the main project documentation or contact your system administrator.
