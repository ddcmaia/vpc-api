import json, os, uuid, boto3, logging
from botocore.exceptions import ClientError

# dynamoDB table with VPC metadata
ddb = boto3.resource("dynamodb").Table(os.getenv("VPC_TABLE"))
log = logging.getLogger()
log.setLevel(logging.INFO)


def handler(event, context):
    # Parse input parameters
    body = json.loads(event.get("body") or "{}")
    region = body.get("region") or os.getenv("AWS_REGION", "us-east-1")
    vpc_range = body.get("vpc_range", "10.0.0.0/16")
    subnet_cfgs = body.get("subnets", [{"range": "10.0.1.0/24", "az": "a"}, {"range": "10.0.2.0/24", "az": "b"},],)

    try:
        # Create regional EC2 client and the VPC
        ec2 = boto3.client("ec2", region_name=region)
        vpc_id = ec2.create_vpc(CidrBlock=vpc_range)["Vpc"]["VpcId"]

        subnets = []
        for cfg in subnet_cfgs:
            az_full = f"{region}{cfg['az']}"
            subnet_id = ec2.create_subnet(
                VpcId=vpc_id,
                CidrBlock=cfg["range"],
                AvailabilityZone=az_full,
            )["Subnet"]["SubnetId"]
            subnets.append({"id": subnet_id, "range": cfg["range"], "az": az_full})

        # store metadata in DynamoDB
        item = {
            "vpc_id": vpc_id,
            "vpc_range": vpc_range,
            "region": region,
            "subnets": subnets,
            "request_id": str(uuid.uuid4()),
        }
        ddb.put_item(Item=item)

        # Send response
        return {"statusCode": 201, "body": json.dumps(item)}

    except (ClientError, Exception) as err:
        log.error("VPC/subnet creation failed: %s", err)
        return {"statusCode": 500, "body": json.dumps({"error": str(err)})}
