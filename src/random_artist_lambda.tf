resource "aws_lambda_function" "random_artist_lambda" {
  function_name = "spotifydb-random-artist-lambda"
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  role          = aws_iam_role.random_artist_lambda_role.arn
  s3_bucket     = aws_s3_bucket.playlist_source_code_bucket.id
  timeout       = 10
  s3_key        = "random-artist-lambda.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.playlist_lambda_vpc_subnet.id]
    security_group_ids = [aws_security_group.mongodb_playlist_lambda_security_group.id]
  }

  environment {
    variables = {
      MONGODB_URI = var.mongodb_uri
    }
  }
}

resource "aws_iam_role" "random_artist_lambda_role" {
  name               = "random-artist-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy" "random_artist_role_execution_policy" {
  role   = aws_iam_role.random_artist_lambda_role.id
  policy = data.aws_iam_policy_document.random_artist_role_execution_policy_document.json
}


data "aws_iam_policy_document" "random_artist_role_execution_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "AllowLogs"
    effect = "Allow"
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    sid    = "AllowVPCOperations"
    effect = "Allow"
    actions = ["ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
    "ec2:DeleteNetworkInterface"]
    resources = ["*"]
  }
}