resource "aws_lb" "application_load_balancer" {
  name               = "spotify-sampler-lb"
  load_balancer_type = "application"

  subnets         = aws_subnet.load_balancer_subnet[*].id
  security_groups = [aws_security_group.load_balancer_sg.id]
}

resource "aws_lb_target_group" "web_server_target_group" {
  name        = "web-server-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ec2_to_mongodbatlas_vpc.id
}

resource "aws_lb_listener" "load_balancer_http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_target_group.arn
  }
}