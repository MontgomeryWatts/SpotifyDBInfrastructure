resource "aws_lambda_function" "lambda" {
  s3_bucket     = "${var.source_bucket_name}"
  s3_key        = "${var.lambda_name}.jar"
  function_name = "${var.lambda_name}"
  memory_size   = "320"
  handler       = "${var.handler_name}"
  runtime       = "java8"
  role          = "${aws_iam_role.lambda_role.arn}"
  timeout       = "5"

  environment {
    variables = {
      BUCKET_NAME    = "${var.datalake_bucket_name}"
      SPOTIFY_ID     = "${var.spotify_id}"
      SPOTIFY_SECRET = "${var.spotify_secret}"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.lambda_name}-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "role_execution_policy" {
  role   = "${aws_iam_role.lambda_role.id}"
  policy = "${data.aws_iam_policy_document.role_execution_policy_document.json}"
}


data "aws_iam_policy_document" "role_execution_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "AllowLogs"
    effect = "Allow"
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}