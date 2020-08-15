resource "aws_lb" "application_load_balancer" {
  name               = "spotify-sampler-lb"
  load_balancer_type = "application"

  subnets         = aws_subnet.load_balancer_subnet[*].id
  security_groups = [aws_security_group.load_balancer_sg.id]
}