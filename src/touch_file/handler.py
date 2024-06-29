import os
from pathlib import Path

EFS_PATH = Path(os.environ["EFS_PATH"])


def touch_efs_file(object_key: str):
    print("Priming file in EFS")
    # Priming file in EFS
    # (This allows downstream lambda to seek the file without checking if it exists)
    target_filename = os.path.join(EFS_PATH, object_key)
    with open(target_filename, "w+b") as _:
        pass  # TODO: write space?


def handler(event, context):
    object_key = event["object_key"]
    touch_efs_file(object_key)
    return {"statusCode": 200, "body": "OK"}
