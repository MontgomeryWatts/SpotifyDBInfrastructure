resource "aws_s3_bucket" "playlist_source_code_bucket" {
  bucket = "spotifydb-playlist-lambdas"
}

resource "aws_lambda_function" "playlist_tranform_lambda" {
  function_name                  = "spotify-playlist-transform-lambda"
  handler                        = "main"
  runtime                        = "go1.x"
  role                           = aws_iam_role.playlist_transform_lambda_role.arn
  s3_bucket                      = aws_s3_bucket.playlist_source_code_bucket.id
  timeout                        = 10
  s3_key                         = "playlist-transform-lambda.zip"
  reserved_concurrent_executions = 50

  vpc_config {
    subnet_ids         = [aws_subnet.playlist_lambda_vpc_subnet.id]
    security_group_ids = [aws_security_group.mongodb_playlist_lambda_security_group.id]
  }

  environment {
    variables = {
      BUCKET_NAME = var.datalake_bucket_name
      MONGODB_URI = var.mongodb_uri
    }
  }
}

resource "aws_iam_role" "playlist_transform_lambda_role" {
  name               = "spotify-playlist-transform-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy" "playlist_tranform_role_execution_policy" {
  role   = aws_iam_role.playlist_transform_lambda_role.id
  policy = data.aws_iam_policy_document.playlist_transform_role_execution_policy_document.json
}


data "aws_iam_policy_document" "playlist_transform_role_execution_policy_document" {
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
  statement {
    sid    = "AllowSQSOperations"
    effect = "Allow"
    actions = ["sqs:ReceiveMessage",
      "sqs:DeleteMessage",
    "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.spotifydb_playlist_transform_sqs.arn]
  }
}

resource "aws_sqs_queue" "spotifydb_playlist_transform_sqs" {
  name = "SpotifyDB-Playlist-Transform-Queue"
}

resource "aws_sqs_queue_policy" "playlist_tranform_sqs_policy" {
  queue_url = aws_sqs_queue.spotifydb_playlist_transform_sqs.id
  policy    = data.aws_iam_policy_document.playlist_transform_queue_policy_document.json
}

data "aws_iam_policy_document" "playlist_transform_queue_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.spotifydb_playlist_transform_sqs.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.spotify_data_topic.arn]
    }
  }
}

resource "aws_sns_topic_subscription" "subscribe_lambda_to_sns" {
  topic_arn            = aws_sns_topic.spotify_data_topic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.spotifydb_playlist_transform_sqs.arn
  raw_message_delivery = true
}

resource "aws_lambda_event_source_mapping" "trigger_playlist_transform_lambda_from_sqs" {
  event_source_arn = aws_sqs_queue.spotifydb_playlist_transform_sqs.arn
  function_name    = aws_lambda_function.playlist_tranform_lambda.arn
  batch_size       = 5
}