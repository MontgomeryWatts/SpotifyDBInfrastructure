resource "aws_sqs_queue" "spotifydb_main_sqs" {

}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = "${aws_sqs_queue.spotifydb_main_sqs.id}"
  policy    = "${data.aws_iam_policy_document.queue_policy_document.json}"
}

data "aws_iam_policy_document" "queue_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = ["${aws_sqs_queue.spotifydb_main_sqs.arn}"]
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

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = "${var.sns_topic_arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.spotifydb_main_sqs.arn}"
}