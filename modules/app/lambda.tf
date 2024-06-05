data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/efs_handler/index.py"    # TODO: Store this path in a variable
  output_path = "${path.module}/archives/efs_lambda.zip" # TODO: Store this path in a variable
}

resource "aws_lambda_function" "lambda_efs" {
  function_name    = "lambda"
  role             = aws_iam_role.lambda_efs_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.8"
  filename         = "${path.module}/archives/efs_lambda.zip" # TODO: Store this path in a variable
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = var.efs_lambda_timeout
  memory_size      = 128
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      EFS_ACCESS_POINT = aws_efs_access_point.efs_access_point.id
    }
  }
  file_system_config {
    local_mount_path = "/mnt/efs"
    arn              = aws_efs_access_point.efs_access_point.arn
  }
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.efs_sg.id]
  }
  depends_on = [aws_efs_mount_target.alpha]
}

# Compare this snippet from lambda.tf:
# resource "aws_lambda_function" "lambda" {
#   function_name = "lambda"
#   role          = aws_iam_role.lambda_role.arn # IAM role ARN for the lambda function to assume when running the function code
#   handler       = "lambda.handler" # The entry point for the lambda function 
#   runtime       = "python3.8" # The runtime environment for the lambda function
#   filename      = "lambda.zip" # The path to the function's deployment package within the local filesystem 
#   source_code_hash = filebase64sha256("lambda.zip") # Used to ensure the function code is not changed between deployments
#   timeout       = 60 # The amount of time the lambda function has to run in seconds
#   memory_size   = 128 # The amount of memory the lambda function has access to in MB
#   environment {
#     variables = {
#       EFS_ACCESS_POINT = aws_efs_access_point.efs_access_point.id 
#     }
#   }
# }
#

