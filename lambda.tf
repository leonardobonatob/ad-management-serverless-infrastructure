data "aws_caller_identity" "current" {}

locals {
    account_id = data.aws_caller_identity.current.account_id
}

resource "random_password" "randomstring" {
  length           = 5
  special          = false
  upper            = false
}

# Zip the Lamda function on the fly
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "lambda/libs"
  output_path = "lambda/remove-computer-ad-function.zip"
}

# Create S3 bucket that will be used to update lambda ziped code
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambda-zip-bucket-${random_password.randomstring.result}"
  acl    = "private"
}

# upload lambda zip to s3 and then update lambda function from s3
resource "aws_s3_bucket_object" "file_upload" {
  bucket = "${aws_s3_bucket.lambda_bucket.id}"
  key    = "lambda-function/remove-computer-ad-function.zip"
  source = "lambda/remove-computer-ad-function.zip" # its mean it depended on zip
}


# Lambda remove computer from AD
resource "aws_lambda_function" "lambda" {
  function_name = "remove-computer-ad-function"
  s3_bucket   = "${aws_s3_bucket.lambda_bucket.id}"
  s3_key      = "${aws_s3_bucket_object.file_upload.key}" 
  source_code_hash = "${base64sha256(data.archive_file.source.output_path)}"
  role    = aws_iam_role.iam_for_lambda.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.8"
  timeout = 10
  
  vpc_config {
    subnet_ids = [aws_subnet.private_subnet.id,aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

    environment {
    variables = {
      DNS_HOSTNAME = "${join(",",aws_directory_service_directory.aws_ad.dns_ip_addresses)}",
      DIRECTORY_NAME = aws_directory_service_directory.aws_ad.name
    }
  }
}

###IAM Role for Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name               = "remove-computer-ad-iam-role"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "test_policy" {
  name = "remove-computer-ad-lambda-policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeTags",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:us-east-1:${local.account_id}:secret:dev/ADcredential*"
      }
    ]
  })
}
