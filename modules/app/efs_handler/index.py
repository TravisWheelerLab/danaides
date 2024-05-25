"""
TODO: Write module docstring.
"""
import json


def lambda_handler(event, context):
    # Write file to attached EFS instance
    file_path = "/mnt/efs/index.html"
    print("Writing file to EFS: ", file_path)
    with open(file_path, "w") as f:
        f.write("Hello from AWS Lambda!")
    # Read file from attached EFS instance
    print("Reading file from EFS: ", file_path)
    with open(file_path, "r") as f:
        content = f.read()
        print("Content: ", content)

    return {"statusCode": 200, "body": json.dumps(content)}
