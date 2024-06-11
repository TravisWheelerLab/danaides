"""
TODO: Write module docstring.
"""
import json


def lambda_handler(event, context):
    """
    Function handler for lambda function that is triggered by an SQS message.

    This function reads the message and writes it to a file on an attached EFS instance.
    """
    print("Event: ", event)
    print("Context: ", context)

    # Read message from SQS
    message = event["Records"][0]["body"]
    print("Message: ", message)
    content = f"Message: {message}"

    # Write the messsage to a file on the attached EFS instance
    file_path = "/mnt/efs/index.html"
    print("Writing file to EFS: ", file_path)
    with open(file_path, "w") as f:
        f.write(content)
    # Read file from attached EFS instance
    print("Reading file from EFS: ", file_path)
    with open(file_path, "r") as f:
        content = f.read()
        print("Content: ", content)

    return {"statusCode": 200, "body": json.dumps(content)}

