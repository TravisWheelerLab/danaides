import logging
import os
from pathlib import Path

logger = logging.getLogger()
logger.setLevel("INFO")

EFS_PATH = Path(os.environ["EFS_PATH"])


def touch_efs_file(object_key: str):
    print("Priming file in EFS")
    # Priming file in EFS
    # (This allows downstream lambda to seek the file without checking if it exists)
    object_key_path = Path(EFS_PATH, object_key)
    object_key_path.parent.mkdir(parents=True, exist_ok=True)
    object_key_path.touch()


def lambda_handler(event, context):
    object_key = event["objectKey"]
    touch_efs_file(object_key)
    return {
        "statusCode": 200,
        "body": {"bucketName": event["bucketName"], "objectKey": object_key},
    }
