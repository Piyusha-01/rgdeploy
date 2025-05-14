#!/bin/bash

# rgdeploy.sh - Unified deployment script for Research Gateway using a single CloudFormation Template (CFT)
# This script provisions ALB, Cognito, DocumentDB, EC2, and all required resources in a single stack.
# VPC and subnets must be created externally and passed as parameters.

# Usage:
#   ./rgdeploy.sh \
#     --ami-id <AMI_ID> \
#     --bucket-name <S3_BUCKET> \
#     --vpc-id <VPC_ID> \
#     --public-subnet-1 <SUBNET_ID> \
#     --public-subnet-2 <SUBNET_ID> \
#     --public-subnet-3 <SUBNET_ID> \
#     --private-subnet-1 <SUBNET_ID> \
#     --private-subnet-2 <SUBNET_ID> \
#     --private-subnet-3 <SUBNET_ID> \
#     --keypair <KEYPAIR_NAME> \
#     --env <ENV> \
#     --rg-url <RG_URL> \
#     --certificate-arn <CERT_ARN> \
#     --region <AWS_REGION>

set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --ami-id) AMI_ID="$2"; shift; shift ;;
    --bucket-name) BUCKET_NAME="$2"; shift; shift ;;
    --vpc-id) VPC_ID="$2"; shift; shift ;;
    --public-subnet-1) PUBLIC_SUBNET_1="$2"; shift; shift ;;
    --public-subnet-2) PUBLIC_SUBNET_2="$2"; shift; shift ;;
    --public-subnet-3) PUBLIC_SUBNET_3="$2"; shift; shift ;;
    --private-subnet-1) PRIVATE_SUBNET_1="$2"; shift; shift ;;
    --private-subnet-2) PRIVATE_SUBNET_2="$2"; shift; shift ;;
    --private-subnet-3) PRIVATE_SUBNET_3="$2"; shift; shift ;;
    --keypair) KEYPAIR_NAME="$2"; shift; shift ;;
    --env) ENVIRONMENT="$2"; shift; shift ;;
    --rg-url) RG_URL="$2"; shift; shift ;;
    --certificate-arn) CERT_ARN="$2"; shift; shift ;;
    --region) REGION="$2"; shift; shift ;;
    *) echo "Unknown option $1"; exit 1 ;;
  esac
done

if [[ -z "$AMI_ID" || -z "$BUCKET_NAME" || -z "$VPC_ID" || -z "$PUBLIC_SUBNET_1" || -z "$PUBLIC_SUBNET_2" || -z "$PUBLIC_SUBNET_3" || -z "$PRIVATE_SUBNET_1" || -z "$PRIVATE_SUBNET_2" || -z "$PRIVATE_SUBNET_3" || -z "$KEYPAIR_NAME" || -z "$ENVIRONMENT" || -z "$RG_URL" || -z "$REGION" ]]; then
  echo "Missing required parameters."
  exit 1
fi

STACK_NAME="RG-PortalStack-ALL-$(date +%s | sha256sum | base64 | tr -dc _a-z-0-9 | head -c 4)"

echo "Packaging and deploying unified Research Gateway stack: $STACK_NAME"

aws cloudformation deploy \
  --template-file rgdeploy-cft.yml \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
  --parameter-overrides \
      AMIId="$AMI_ID" \
      CFTBucketName="$BUCKET_NAME" \
      VPC="$VPC_ID" \
      PublicSubnet1="$PUBLIC_SUBNET_1" \
      PublicSubnet2="$PUBLIC_SUBNET_2" \
      PublicSubnet3="$PUBLIC_SUBNET_3" \
      PrivateSubnet1="$PRIVATE_SUBNET_1" \
      PrivateSubnet2="$PRIVATE_SUBNET_2" \
      PrivateSubnet3="$PRIVATE_SUBNET_3" \
      KeyPairName="$KEYPAIR_NAME" \
      Environment="$ENVIRONMENT" \
      RGUrl="$RG_URL" \
      CertificateArn="$CERT_ARN"

echo "Deployment initiated. Monitor stack progress in the AWS CloudFormation console."
