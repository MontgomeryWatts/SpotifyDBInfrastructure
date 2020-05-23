resource "aws_dynamodb_table" "tracking_table" {
  name           = "TrackingTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10

  hash_key = "EntityURI"

  attribute {
    name = "EntityURI"
    type = "S"
  }
}
