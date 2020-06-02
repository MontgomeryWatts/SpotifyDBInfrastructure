resource "aws_api_gateway_rest_api" "spotifydb_api" {
  name        = "SpotifyDBAPI"
  description = "API Gateway for SpotifyDB"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "root_resource" {
  path_part   = "api"
  parent_id   = aws_api_gateway_rest_api.spotifydb_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "albums_resource" {
  path_part   = "albums"
  parent_id   = aws_api_gateway_resource.root_resource.id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "artists_resource" {
  path_part   = "artists"
  parent_id   = aws_api_gateway_resource.root_resource.id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}

resource "aws_api_gateway_resource" "random_artists_resource" {
  path_part   = "random"
  parent_id   = aws_api_gateway_resource.artists_resource.id
  rest_api_id = aws_api_gateway_rest_api.spotifydb_api.id
}