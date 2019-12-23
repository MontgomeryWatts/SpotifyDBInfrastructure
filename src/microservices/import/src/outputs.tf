output "producer_arns" {
  value       = ["${module.import-entity-lambda.lambda_role_arn}"]
  description = "The ARNs of resources that should be granted PUT access to the datalake"
}
