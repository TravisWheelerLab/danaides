import csv
import io
import logging
import os
from io import StringIO

import boto3

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Set constants from environment variables
MANIFEST_BUCKET_NAME = os.environ["MANIFEST_BUCKET_NAME"]
BLOCK_SIZE_MB = int(os.environ["BLOCK_SIZE_MB"])

# Create S3 client
# (It is best practice for boto3 clients be set at global scope)
s3_client = boto3.client("s3")


def generate_manifest_data(object_size_bytes: int, block_size_bytes: int) -> StringIO:

    print("Splitting blocks")
    blocks = []
    # Calculate the start byte for each block
    for start_byte in range(0, object_size_bytes, block_size_bytes):
        end_byte = min(start_byte + block_size_bytes - 1, object_size_bytes - 1)
        blocks.append((start_byte, end_byte))

    print("Writing csv")
    # Prepare the CSV data
    csv_data = io.StringIO()
    csv_writer = csv.writer(csv_data)
    csv_writer.writerow(["startByte", "endByte"])
    csv_writer.writerows([[start_byte, end_byte] for start_byte, end_byte in blocks])

    return csv_data


def assert_source_bucket_region(bucket_name: str):
    # Check if the bucket exists in the same region as this lambda
    # (This is a best practice for performance)
    bucket_region = s3_client.get_bucket_location(Bucket=bucket_name)[
        "LocationConstraint"
    ]
    current_region = os.environ["AWS_REGION"]
    if bucket_region != current_region:
        raise ValueError(
            # string that spans two lines
            f"Bucket {bucket_name} is in a different region ({bucket_region}) "
            + "than this lambda ({current_region})"
        )


def lambda_handler(event, context):
    logger.info("Event: %s", event)

    bucket_name = event["bucketName"]
    object_key = event["objectKey"]
    block_size_bytes = BLOCK_SIZE_MB * 1024 * 1024
    logger.info(
        "Bucket: %s, Object: %s, Block size: %s",
        bucket_name,
        object_key,
        block_size_bytes,
    )

    # Ensure bucket exists in the same region as the application
    try:
        assert_source_bucket_region(bucket_name)
    except ValueError as e:
        logger.error("Error: %s", e)
        return {
            "statusCode": 400,
            "body": str(e),
        }
    # Get the size of the S3 object
    logger.info("Getting object size in S3")
    response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
    logger.info("Response: %s", response)

    object_size_bytes = int(response["ContentLength"])
    logger.info("Object size: %s", object_size_bytes)

    # Generate manifest file
    logger.info("Generating manifest file")
    csv_data = generate_manifest_data(object_size_bytes, block_size_bytes)

    print("Uploading to s3")
    # Upload the CSV file to S3
    manifest_object_key = f"manifests/{object_key}.csv"
    s3_client.put_object(
        Bucket=MANIFEST_BUCKET_NAME, Key=manifest_object_key, Body=csv_data.getvalue()
    )

    return {
        "statusCode": 200,
        "body": {
            "manifestBucketName": MANIFEST_BUCKET_NAME,
            "manifestObjectKey": manifest_object_key,
        },
    }
