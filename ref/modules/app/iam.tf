


resource "aws_iam_role" "lambda_efs_role" {
  name = "lambda_efs_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy" "lambda_execute_policy" {
  arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "lambda_execute_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.lambda_execute_policy.arn
}

data "aws_iam_policy" "lambda_vpc_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.lambda_vpc_policy.arn
}

data "aws_iam_policy" "efs_full_access_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
}

resource "aws_iam_role_policy_attachment" "efs_full_access_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.efs_full_access_policy.arn
}

data "aws_iam_policy" "cloudwatch_logs_policy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.cloudwatch_logs_policy.arn
}

data "aws_iam_policy" "s3_full_access_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.s3_full_access_policy.arn
}

data "aws_iam_policy" "ddb_full_access_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "ddb_full_access_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.ddb_full_access_policy.arn
}

data "aws_iam_policy" "lambda_sqs_execution_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_execution_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.lambda_sqs_execution_policy.arn
}
