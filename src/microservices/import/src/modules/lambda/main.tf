locals {
  sqs_visibility_timeout_seconds = "${var.lambda_timeout_seconds * 6}" # https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#events-sqs-queueconfig
}


resource "aws_lambda_function" "lambda" {
  s3_bucket     = "${var.source_bucket_name}"
  s3_key        = "${var.lambda_file_name}"
  function_name = "${var.lambda_name}"
  memory_size   = "${var.lambda_memory_size}"
  handler       = "${var.handler_name}"
  runtime       = "${var.lambda_runtime}"
  role          = "${aws_iam_role.lambda_role.arn}"
  timeout       = "${var.lambda_timeout_seconds}"

  environment {
    variables = "${var.lambda_environment_variables}"
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
  statement {
    sid    = "AllowSQSOperations"
    effect = "Allow"
    actions = ["sqs:ReceiveMessage",
      "sqs:DeleteMessage",
    "sqs:GetQueueAttributes"]
    resources = ["${aws_sqs_queue.sqs.arn}"]
  }
}

resource "aws_lambda_event_source_mapping" "trigger_lambda_from_sqs" {
  event_source_arn = "${aws_sqs_queue.sqs.arn}"
  function_name    = "${aws_lambda_function.lambda.arn}"
  batch_size       = "${var.messages_per_lambda_invocation}"
}


resource "aws_sqs_queue" "sqs" {
  visibility_timeout_seconds = "${local.sqs_visibility_timeout_seconds}"
  receive_wait_time_seconds  = "20"
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = "${aws_sqs_queue.sqs.id}"
  policy    = "${data.aws_iam_policy_document.queue_policy_document.json}"
}

data "aws_iam_policy_document" "queue_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = ["${aws_sqs_queue.sqs.arn}"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["${var.sns_topic_arn}"]
    }
  }
}

resource "aws_sns_topic_subscription" "subscribe_sqs_to_sns" {
  protocol             = "sqs"
  topic_arn            = "${var.sns_topic_arn}"
  endpoint             = "${aws_sqs_queue.sqs.arn}"
  filter_policy        = "${jsonencode(map("entity_type", var.entity_types))}"
  raw_message_delivery = "true"
}