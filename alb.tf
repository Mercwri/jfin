resource "aws_security_group" "alb" {
  name   = "jellyfin-alb-sg"
  vpc_id = aws_vpc.core.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "jellyfin-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in aws_subnet.core : s.id]
}

resource "aws_lb_target_group" "jf" {
  name     = "jellyfin-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.core.id
  health_check {
    enabled = true
    path    = "/"
    matcher = "200,302"
  }
}

resource "aws_lb_listener" "http_no_ssl" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jf.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.jf_certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jf.arn
  }
}

resource "aws_lb_target_group_attachment" "jf" {
  target_group_arn = aws_lb_target_group.jf.arn
  target_id        = aws_instance.jellyfin.id
  port             = 80
}
