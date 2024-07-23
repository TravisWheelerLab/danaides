import json
import logging
import os
from pathlib import Path

import boto3

# You can reference EFS files by including your local mount path, and then
# treat them like any other file. Local invokes may not work with this, however,
# as the file/folders may not be present in the container.
EFS_PATH = Path(os.environ["EFS_PATH"])
logger = logging.getLogger()
logger.setLevel("INFO")


def lambda_handler(event, context):
    logger.info(f"Event: {event}")

    # NOTE: This function is enabled for reporting Batch item failures.
    # If an error occurs while processing a message, the message ID is added to
    # the `batch_item_failures` list. This list is then returned in the response.
    # The Lambda service will automatically retry the failed messages.

    batch_item_failures = []
    sqs_batch_response = {}

    messages = event["Records"]
    for message in messages:

        logger.info("Processing message")
        logger.info(f"Message: {message}")

        data = json.loads(message["body"])
        source_bucket_name = data["sourceBucketName"]
        source_object_key = data["sourceObjectKey"]
        start_byte = data["startByte"]
        end_byte = data["endByte"]

        logger.info(f"Source bucket: {source_bucket_name}")
        logger.info(f"Source object: {source_object_key}")
        logger.info(f"Start byte: {start_byte}")
        logger.info(f"End byte: {end_byte}")

        try:
            logger.info("Reading byte range from S3")
            s3_client = boto3.client("s3")
            response = s3_client.get_object(
                Bucket=source_bucket_name,
                Key=source_object_key,
                Range=f"bytes={start_byte}-{end_byte}",
            )
            logger.info("Response: %s", response)

            # Write byte range to EFS
            logger.info("Writing byte range to EFS")
            efs_file_path = os.path.join(EFS_PATH, source_object_key)
            with open(efs_file_path, "w+b") as f:
                f.write(response["Body"].read())

            logger.info("Finished processing message")
        except Exception as e:
            logger.error("Error: %s", e)
            batch_item_failures.append({"itemIdentifier": message["messageId"]})
            continue

    sqs_batch_response["batchItemFailures"] = batch_item_failures

    return sqs_batch_response
