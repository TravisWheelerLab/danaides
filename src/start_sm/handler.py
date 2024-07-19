"""
Lambda handler to start a StepFunction state machine execution
"""

import json
import os
import uuid

import boto3


def lambda_handler(event, context):
    client = boto3.client('stepfunctions')
    response = client.start_execution(
        stateMachineArn=os.environ['STATE_MACHINE_ARN'],
        name=f'execution-{uuid.uuid4}',
        input='{}'
    )
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }

