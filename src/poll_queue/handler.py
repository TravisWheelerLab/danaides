import os

import boto3

# Initialize the SQS client
queue_url = os.environ["BLOCK_QUEUE_URL"]
sqs = boto3.client("sqs", endpoint_url=queue_url)


def lambda_handler(event, context):
    try:
        # Get the number of messages in the SQS queue
        response = sqs.get_queue_attributes(
            QueueUrl=queue_url, AttributeNames=["ApproximateNumberOfMessages"]
        )

        # Retrieve the number of messages
        num_messages = int(response["Attributes"]["ApproximateNumberOfMessages"])
        payload = {"queueEmpty": (num_messages == 0)}

        return {"statusCode": 200, "body": payload}

    except Exception as e:
        # Handle any exceptions that occur during the check
        return f"Error: {str(e)}"
