[
  {
    "name": "web-server",
    "image": "${aws_ecr_repository}:${tag}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "MONGODB_URI",
        "value": "${mongodb_uri}"
      }
    ]
  }
]