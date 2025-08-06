import json, os, boto3

# dynamoDB table with VPC metadata
ddb = boto3.resource("dynamodb").Table(os.getenv("VPC_TABLE"))

def handler(event, context):
    # fetch VPC record by ID
    vpc_id = event["pathParameters"]["id"]
    resp = ddb.get_item(Key={"vpc_id": vpc_id})
    if "Item" not in resp:
        return {"statusCode": 404, "body": "Not found"}
    return {"statusCode": 200, "body": json.dumps(resp["Item"])}
