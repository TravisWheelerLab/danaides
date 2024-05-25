data "aws_iam_policy" "lambda_execute_policy" {
  arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

data "aws_iam_policy" "lambda_vpc_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy" "efs_full_access_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
}

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

resource "aws_iam_role_policy_attachment" "lambda_execute_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.lambda_execute_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.lambda_vpc_policy.arn
}

resource "aws_iam_role_policy_attachment" "efs_full_access_policy_attachment" {
  role       = aws_iam_role.lambda_efs_role.name
  policy_arn = data.aws_iam_policy.efs_full_access_policy.arn
}

