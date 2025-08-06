# Sample VPC‑as‑a‑Service 

This sample repo spins up a serverless API (API Gateway + Cognito auth) that lets you
create VPCs with arbitrary subnet CIDRs and stores the metadata in DynamoDB.

## Step by step

1. **Configure your AWS credentials**

   ```bash
   aws configure
   ```

2. **Create the S3 bucket to store the state**

   ```bash
   aws s3api create-bucket --bucket tests-maia --region us-east-1
   ```

3. **Initialize and apply Terraform**

   ```bash
   terraform init
   terraform plan  
   terraform apply
   ```

4. **Retrieve the outputs**

   ```bash
   export API_URL=$(terraform output -raw api_url)
   export USER_POOL_ID=$(terraform output -raw user_pool_id)
   export COGNITO_APP_CLIENT_ID=$(terraform output -raw cognito_app_client_id)
   ```

5. **Register a user and obtain an ID token**

   ```bash
   aws cognito-idp sign-up \
       --client-id $COGNITO_APP_CLIENT_ID \
       --username usertest \
       --password SuperSecret123!

   aws cognito-idp admin-confirm-sign-up \
       --user-pool-id $USER_POOL_ID \
       --username usertest

   ID_TOKEN=$(aws cognito-idp initiate-auth \
       --client-id $COGNITO_APP_CLIENT_ID \
       --auth-flow USER_PASSWORD_AUTH \
       --auth-parameters USERNAME=usertest,PASSWORD=SuperSecret123! \
       --query "AuthenticationResult.IdToken" \
       --output text)
   ```

6. **Test the API**

   ```bash
   # create VPC
   curl -X POST "$API_URL/vpcs" \
      -H "Authorization: Bearer $ID_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
            "region": "us-east-1", 
            "vpc_range": "10.0.0.0/16",
            "subnets": [
               { "range": "10.0.1.0/24", "az": "a" },
               { "range": "10.0.2.0/24", "az": "b" }
            ]
         }'

   # response looks like this and contains the VPC ID
   {"vpc_id": "vpc-0b3a7a20d52565a72", "vpc_range": "10.0.0.0/16", "region": "us-east-2", "subnets": [{"id": "subnet-0ee5b4ecda3f9b7e4", "range": "10.0.1.0/24", "az": "us-east-2a"}, {"id": "subnet-00597a16e498dabaa", "range": "10.0.2.0/24", "az": "us-east-2b"}], "request_id": "beab8712-11bd-4617-ab5c-fee2039e1a62"}%    

   # get VPC (replace <vpc_id> with the ID returned above)
   curl -X GET "$API_URL/vpcs/<vpc_id>" \
      -H "Authorization: Bearer $ID_TOKEN"
   ```

7. **Verify the state storage**

   ```bash
   aws s3 ls s3://tests-maia
   ```

