import os
import time

import boto3

# Initialize the SQS client
queue_url = os.environ["BLOCK_QUEUE_URL"]
sqs = boto3.client("sqs")

# Configuration parameters
CHECK_INTERVAL_SECONDS = 5
NUM_CHECKS = 3


def lambda_handler(event, context):
    try:
        empty_check_count = 0

        for _ in range(NUM_CHECKS):
            # Get the number of messages in the SQS queue
            response = sqs.get_queue_attributes(
                QueueUrl=queue_url,
                AttributeNames=[
                    "ApproximateNumberOfMessages",
                    "ApproximateNumberOfMessagesNotVisible",
                ],
            )

            # Retrieve the number of messages
            num_messages = int(
                response["Attributes"]["ApproximateNumberOfMessages"]
            ) + int(response["Attributes"]["ApproximateNumberOfMessagesNotVisible"])

            if num_messages == 0:
                empty_check_count += 1

            # Wait for a while before the next check
            time.sleep(CHECK_INTERVAL_SECONDS)

        # Determine if the queue is empty based on consistent results
        queue_empty = empty_check_count == NUM_CHECKS
        payload = {"queueEmpty": queue_empty}

        return {"statusCode": 200, "body": payload}

    except Exception as e:
        # Handle any exceptions that occur during the check
        return {"statusCode": 500, "body": f"Error: {str(e)}"}
