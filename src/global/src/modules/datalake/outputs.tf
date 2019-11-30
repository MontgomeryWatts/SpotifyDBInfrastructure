output "sns_topic_arn" {
  value = "${aws_sns_topic.spotify_data_topic.arn}"
}
