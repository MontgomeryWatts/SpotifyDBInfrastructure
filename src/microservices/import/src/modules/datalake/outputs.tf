output "sns_topic_arn" {
  value       = "${aws_sns_topic.spotify_data_topic.arn}"
  description = "The ARN of the SNS Topic to subscribe to if you want to be alerted of new data in the datalake"
}
