import io
import os
import csv
import json
from pathlib import Path
from io import StringIO

import boto3
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set constants from environment variables
MANIFEST_BUCKET_NAME = os.environ['MANIFEST_BUCKET_NAME']
BLOCK_SIZE_MB = int(os.environ['BLOCK_SIZE_MB'])
EFS_PATH = Path(os.environ['EFS_PATH'])

# Create S3 client
# (It is best practice for boto3 clients be set at global scope)
s3_client = boto3.client('s3')


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
    csv_writer.writerow(['start_byte', 'end_byte'])
    csv_writer.writerows([[start_byte, end_byte] for start_byte, end_byte in blocks])

    return csv_data


def touch_efs_file(object_key: str):

    print("Priming file in EFS")
    # Priming file in EFS
    # (This allows downstream lambda to seek the file without checking if it exists)
    target_filename = os.path.join(EFS_PATH, object_key)
    with open(target_filename, 'w+b') as _:
        pass # TODO: write space?


def lambda_handler(event, context):
    logger.info('Event: %s', event)

    # TODO: Validate that the bucket is in the same region as the VPC, else fail
    bucket_name = event['bucketName']
    object_key = event['objectKey']
    block_size_bytes = BLOCK_SIZE_MB * 1024 * 1024
    logger.info('Bucket: %s, Object: %s, Block size: %s', bucket_name, object_key, block_size_bytes)

    # Get the size of the S3 object
    logger.info('Getting object size in S3')
    response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
    logger.info('Response: %s', response)
    
    object_size_bytes = int(response['ContentLength'])
    logger.info('Object size: %s', object_size_bytes)

    # Generate manifest file
    logger.info('Generating manifest file')
    csv_data = generate_manifest_data(object_size_bytes, block_size_bytes)
    
    print("Uploading to s3")
    # Upload the CSV file to S3
    manifest_object_key = f"manifests/{object_key}.csv"
    s3_client.put_object(Bucket=MANIFEST_BUCKET_NAME, Key=manifest_object_key, Body=csv_data.getvalue())

    return {
        'statusCode': 200,
        'body': json.dumps({
            'manifestBucketName': MANIFEST_BUCKET_NAME,
            'manifestObjectKey': manifest_object_key,
        }),
    }
