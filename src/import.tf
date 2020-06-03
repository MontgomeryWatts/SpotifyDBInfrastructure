locals {
  spotify_environment_variables = {
    SPOTIFY_ID     = var.spotify_id
    SPOTIFY_SECRET = var.spotify_secret
    TABLE_NAME     = aws_dynamodb_table.import_tracking_table.name
  }
  import_environment_variables = merge(local.spotify_environment_variables, {
    BUCKET_NAME = aws_s3_bucket.datalake_bucket.id
  })

  fan_out_environment_variables = merge(local.spotify_environment_variables, {
    TOPIC_ARN = aws_sns_topic.import_data_topic.arn
  })
}

resource "aws_s3_bucket" "import_source_code_bucket" {
  bucket = "spotifydb-import-lambdas"
}

resource "aws_sns_topic" "import_data_topic" {
  name = "import-data-topic"
}

resource "aws_dynamodb_table" "import_tracking_table" {
  name         = "TrackingTable"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "EntityURI"

  attribute {
    name = "EntityURI"
    type = "S"
  }
}


data "aws_iam_policy_document" "import_topic_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.import_data_topic.arn]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.import_fan_out_lambda_role.arn]
    }
  }
}

resource "aws_sns_topic_policy" "import_data_topic_policy" {
  arn    = "${aws_sns_topic.import_data_topic.arn}"
  policy = "${data.aws_iam_policy_document.import_topic_policy_document.json}"
}


########################
# Import Entity Lambda #
########################


resource "aws_lambda_function" "import_entity_lambda" {
  s3_bucket                      = aws_s3_bucket.import_source_code_bucket.id
  s3_key                         = "import-entity-lambda.zip"
  function_name                  = "spotifydb-import-entity-lambda"
  memory_size                    = 128
  handler                        = "main"
  runtime                        = "go1.x"
  role                           = aws_iam_role.import_entity_lambda_role.arn
  timeout                        = 15
  reserved_concurrent_executions = 5

  environment {
    variables = local.import_environment_variables
  }
}

resource "aws_iam_role" "import_entity_lambda_role" {
  name               = "spotifydb-import-entity-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}


resource "aws_iam_role_policy" "import_entity_lambda_role_execution_policy" {
  role   = aws_iam_role.import_entity_lambda_role.id
  policy = data.aws_iam_policy_document.import_entity_lambda_role_execution_policy_document.json
}


data "aws_iam_policy_document" "import_entity_lambda_role_execution_policy_document" {
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
    resources = [aws_sqs_queue.import_entity_sqs_queue.arn]
  }
  statement {
    sid       = "AllowDynamoDBOperations"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.import_tracking_table.arn]
  }
}

resource "aws_lambda_event_source_mapping" "trigger_import_entity_lambda_from_sqs" {
  event_source_arn = aws_sqs_queue.import_entity_sqs_queue.arn
  function_name    = aws_lambda_function.import_entity_lambda.arn
  batch_size       = 10
}


resource "aws_sqs_queue" "import_entity_sqs_queue" {
  name                       = "${aws_lambda_function.import_entity_lambda.id}Queue"
  visibility_timeout_seconds = aws_lambda_function.import_entity_lambda.timeout * 6
  receive_wait_time_seconds  = 20
}

resource "aws_sqs_queue_policy" "import_entity_sqs_policy" {
  queue_url = aws_sqs_queue.import_entity_sqs_queue.id
  policy    = data.aws_iam_policy_document.import_entity_queue_policy_document.json
}

data "aws_iam_policy_document" "import_entity_queue_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.import_entity_sqs_queue.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.import_data_topic.arn]
    }
  }
}

resource "aws_sns_topic_subscription" "subscribe_import_entity_sqs_to_sns" {
  protocol             = "sqs"
  topic_arn            = aws_sns_topic.import_data_topic.arn
  endpoint             = aws_sqs_queue.import_entity_sqs_queue.arn
  filter_policy        = jsonencode(map("entity_type", ["album", "artist"]))
  raw_message_delivery = true
}

##################
# Fan Out Lambda #
##################

resource "aws_lambda_function" "import_fan_out_lambda" {
  s3_bucket                      = aws_s3_bucket.import_source_code_bucket.id
  s3_key                         = "import-entity-lambda.zip"
  function_name                  = "spotifydb-import-fan-out-lambda"
  memory_size                    = 128
  handler                        = "main"
  runtime                        = "go1.x"
  role                           = aws_iam_role.import_fan_out_lambda_role.arn
  timeout                        = 120
  reserved_concurrent_executions = 0

  environment {
    variables = local.fan_out_environment_variables
  }
}

resource "aws_iam_role" "import_fan_out_lambda_role" {
  name               = "spotifydb-import-fan-out-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy" "import_fan_out_lambda_role_execution_policy" {
  role   = aws_iam_role.import_fan_out_lambda_role.id
  policy = data.aws_iam_policy_document.import_fan_out_lambda_role_execution_policy_document.json
}


data "aws_iam_policy_document" "import_fan_out_lambda_role_execution_policy_document" {
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
    resources = [aws_sqs_queue.import_fan_out_sqs_queue.arn]
  }
  statement {
    sid       = "AllowDynamoDBOperations"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.import_tracking_table.arn]
  }
}

resource "aws_lambda_event_source_mapping" "trigger_import_fan_out_lambda_from_sqs" {
  event_source_arn = aws_sqs_queue.import_fan_out_sqs_queue.arn
  function_name    = aws_lambda_function.import_fan_out_lambda.arn
  batch_size       = 1
}


resource "aws_sqs_queue" "import_fan_out_sqs_queue" {
  name                       = "${aws_lambda_function.import_fan_out_lambda.id}Queue"
  visibility_timeout_seconds = aws_lambda_function.import_fan_out_lambda.timeout * 6
  receive_wait_time_seconds  = 20
}

resource "aws_sqs_queue_policy" "import_fan_out_sqs_policy" {
  queue_url = aws_sqs_queue.import_fan_out_sqs_queue.id
  policy    = data.aws_iam_policy_document.import_fan_out_queue_policy_document.json
}

data "aws_iam_policy_document" "import_fan_out_queue_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.import_fan_out_sqs_queue.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.import_data_topic.arn]
    }
  }
}

resource "aws_sns_topic_subscription" "subscribe_import_fan_out_sqs_to_sns" {
  protocol             = "sqs"
  topic_arn            = aws_sns_topic.import_data_topic.arn
  endpoint             = aws_sqs_queue.import_fan_out_sqs_queue.arn
  filter_policy        = jsonencode(map("entity_type", ["artist"]))
  raw_message_delivery = true
}