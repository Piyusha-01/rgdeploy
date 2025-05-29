# Research Gateway Single-CFT Deployment Guide

This guide describes how to deploy the Research Gateway application using the new single-stack CloudFormation approach. All AWS resources (Cognito, DocumentDB, EC2, etc.) are provisioned in one unified stack, and the EC2 instance configures itself automatically using stack outputs. The stack also creates the first admin user using the provided email address.

---

## Overview

- **Single CFT**: All AWS resources are created by a single CloudFormation template (`rgdeploy-cft.yml`).
- **External ALB Integration**: The template accepts an existing ALB and Target Group ARN as parameters.
- **Automated Configuration**: The EC2 instance generates its configuration at launch using `makeconfigs.sh`, with parameters derived from stack outputs.
- **Wrapper Script**: The `rgdeploy.sh` script wraps the deployment, handling parameter passing and stack creation.

---

## Prerequisites

1. **AWS Account** with sufficient permissions to create VPC, EC2, IAM, Cognito, DocumentDB, S3, and related resources.
2. **VPC and Subnets**: You must have an existing VPC with at least 3 public and 3 private subnets.
3. **Application Load Balancer**: An existing ALB with its ARN available.
4. **Target Group**: An existing Target Group with its ARN available.
5. **ACM Certificate** (optional): For SSL, create or import a certificate in AWS Certificate Manager.
6. **AWS CLI**: Installed and configured (`aws configure`).
7. **jq**: Installed on your local machine and available in the EC2 AMI.
8. **S3 Bucket**: A bucket to store deployment scripts and configuration files.
9. **Scripts**: Ensure the following files are uploaded to your S3 bucket:
    - `makeconfigs.sh`
    - `updatescripts.sh`
    - `post_verification_send_message.zip`
    - `pre_verification_custom_message.zip`
    - Any other scripts referenced in UserData or by the application
10. **CloudFormation Template**: `rgdeploy-cft.yml` must be present in your working directory.

---

## Parameters Required

1. **Upload Scripts to S3**

   ```bash
   aws s3 cp makeconfigs.sh s3://<your-bucket>/
   aws s3 cp updatescripts.sh s3://<your-bucket>/
   # Upload any other required scripts
   ```

2. **Prepare Parameters**

Gather the following information
 ------------------------------------------------------------------------------------------------------
| **Parameter**               | **Description**                                                        |
| --------------------------- | ---------------------------------------------------------------------- |
| `RgSRC`                     | Directory path for deployment files (Default: `/home/ubuntu/rgdeploy`) |
| `AMIId`                     | Amazon Machine Image ID used to launch the EC2 instance                |
| `CFTBucketName`             | Name of the S3 bucket storing CloudFormation templates                 |
| `VPC`                       | ID of the VPC where the infrastructure will be deployed                |
| `PublicSubnet1`             | ID of the first public subnet                                          |
| `PublicSubnet2`             | ID of the second public subnet                                         |
| `PublicSubnet3`             | ID of the third public subnet                                          |
| `PrivateSubnet1`            | ID of the first private subnet                                         |
| `PrivateSubnet2`            | ID of the second private subnet                                        |
| `PrivateSubnet3`            | ID of the third private subnet                                         |
| `KeyPairName`               | Name of the EC2 Key Pair used for SSH access                           |
| `Environment`               | Deployment environment (`DEV`, `QA`, `STAGE`, `PROD`)                  |
| `RGUrl`                     | Research Gateway URL (e.g., `https://myrg.example.com`)                |
| `RGApplicationLoadBalancer` | ARN of the existing Application Load Balancer                          |
| `CertificateArn`            | ARN of the ACM Certificate (optional; used for enabling SSL/TLS)       |
| `HostedZoneId`              | Route 53 Hosted Zone ID for domain name configuration                  |
| `RGTargetGroupArn`          | ARN of the existing Target Group for load balancing                    |
| `BaseAccountPolicyName`     | Name of the base IAM policy for RG Portal accounts                     |
| `AdminEmail`                | Email address of the initial administrator user                        |
| `region`                    | AWS region where the stack will be deployed                            |
 ------------------------------------------------------------------------------------------------------

---

## Deployment Steps

1. **Run the Deployment Script**

Replace all values in angle brackets (`<...>`) with your actual configuration.

```bash
./rgdeploy.sh \
  --rg-src <RG_SRC> \
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
  --alb-arn <ALB_ARN> \
  --target-group-arn <TARGET_GROUP_ARN> \
  --certificate-arn <CERT_ARN> \
  --region <AWS_REGION> \
  --hostedzoneid <ROUTE53_HOSTED_ZONE_ID> \
  --base-account-policy-name <BASE_ACCOUNT_POLICY_NAME> \
  --admin-email <ADMIN_EMAIL>
```

---

## Deployment Script Example

Below is a sample deployment command with example values.

```bash
./rgdeploy.sh \
  --rg-src /home/ubuntu/rgdeploy \
  --ami-id ami-0abcdef1234567890 \
  --bucket-name my-rgdeploy-bucket \
  --vpc-id vpc-0123456789abcdef0 \
  --public-subnet-1 subnet-aaa111bbb222ccc33 \
  --public-subnet-2 subnet-bbb222ccc333ddd44 \
  --public-subnet-3 subnet-ccc333ddd444eee55 \
  --private-subnet-1 subnet-xxx111yyy222zzz33 \
  --private-subnet-2 subnet-yyy222zzz333aaa44 \
  --private-subnet-3 subnet-zzz333aaa444bbb55 \
  --keypair my-ec2-keypair \
  --env DEV \
  --rg-url https://myrg.example.com \
  --alb-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188 \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-tg/6d0ecf831eec9f09 \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-abcd-1234-abcd-1234abcd1234 \
  --region us-east-1 \
  --hostedzoneid Z3P5QSUBK4POTI \
  --base-account-policy-name RG-Base-Account-Policy \
  --admin-email admin@example.com
```

**Notes:**
- All parameters are required except `--certificate-arn` (omit for non-SSL).
- Ensure the ALB and Target Group ARNs are correct and exist in your AWS account.
- The script will deploy the unified stack using `rgdeploy-cft.yml`.

2. **What Happens During Deployment**

- The CloudFormation stack provisions all AWS resources in the correct order.
- The EC2 instance, on first boot, downloads the necessary scripts from S3.
- It generates application configuration files by running `makeconfigs-inplace.sh`, using live stack outputs.
- The application is started automatically.
- The first admin user is created using the provided `AdminEmail`.

---

## Post-Deployment

- **Access the Application**: Use the URL you provided (`--rg-url`) to access the Research Gateway portal, and log in using the credentials of the newly created admin user.
- **EC2 Instance**: The instance will be running in your private subnet, registered with the ALB via the Target Group.
- **Cognito & DocumentDB**: User authentication and data storage are fully configured.
- **Route53**: Ensure your domain's DNS is set up to point to the ALB if using a custom domain.

---

## Troubleshooting

- **Stack Creation Fails**: Check the CloudFormation console for error messages and resource status.
- **EC2 Boot Issues**: Review the EC2 instance's system logs and `/var/log/user-data.log`.
- **Configuration Issues**: Ensure all scripts are present in S3 and the AMI includes `jq` and other dependencies.
- **SSL/Domain Issues**: Verify your ACM certificate is valid and in the correct region, and that Route53 records are correct.
- **ALB/Target Group Issues**: Verify that the provided ARNs are correct and that the Target Group is properly configured for the EC2 instance.

---

## Tips

- **Rollback**: If the stack fails, CloudFormation will roll back all resources.
- **Re-deploy**: You can delete the stack and re-run the deployment as needed.
- **Custom AMI**: Use an AMI with all required software (docker, jq, awscli, etc.) pre-installed for smoother setup.
- **IAM Permissions**: The template creates an IAM role with necessary permissions for the EC2 instance, including S3 access, Cognito management, and more.

---

## Support

For further assistance, refer to the main project documentation or contact your system administrator.
