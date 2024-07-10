import json

import boto3
import moto
import pytest

from src.write_manifest import handler


@pytest.fixture()
def apigw_event():
    """Generates API GW Event"""

    return {
        "bucketName": "sam-efs-lambda-269654799220-us-west-2",
        "objectKey": "dbgap-df.csv",
    }


def test_generate_manifest_data():
    object_size_bytes = 100
    block_size_bytes = 10
    csv_data = handler.generate_manifest_data(object_size_bytes, block_size_bytes)
    csv_data.seek(0)
    csv_data_str = csv_data.read()
    assert (
        csv_data_str
        == "start_byte,end_byte\r\n0,9\r\n10,19\r\n20,29\r\n30,39\r\n40,49\r\n50,59\r\n60,69\r\n70,79\r\n80,89\r\n90,99\r\n"
    )


@moto.mock_aws
def test_assert_source_bucket_region():
    test_bucket = "test-bucket"
    conn = boto3.resource("s3", region_name="us-west-2")
    conn.create_bucket(
        Bucket=test_bucket,
        CreateBucketConfiguration={"LocationConstraint": "us-west-2"},
    )
    handler.assert_source_bucket_region(test_bucket)


@moto.mock_aws
def test_lambda_handler_write_file(apigw_event, mocker):
    # file_mock = mocker.patch.object(handler, 'FILE')
    # file_mock.is_file.return_value = False
    test_bucket = "test-bucket"
    test_region = "us-west-2"
    test_key = "test-key"
    conn = boto3.resource("s3")
    conn.create_bucket(
        Bucket=test_bucket,
        CreateBucketConfiguration={"LocationConstraint": test_region},
    )
    # Write a file to the bucket
    conn.Object(test_bucket, test_key).put(Body="Test file\n")

    event = {"bucketName": test_bucket, "objectKey": test_key}

    ret = handler.lambda_handler(event, "")
    data = json.loads(ret["body"])

    assert ret["statusCode"] == 200
    # assert "file_contents" in ret["body"]
    # assert "created_file" in ret["body"]
    # assert data["file_contents"] == "Hello, EFS!\n"
    # assert data["created_file"] == True
