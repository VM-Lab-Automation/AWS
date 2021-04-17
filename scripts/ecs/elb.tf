
resource "aws_security_group" "sg_lb" {
  name = "lb-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    description = "HTTP Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8000"
    to_port     = "8000"
    protocol    = "tcp"
    description = "Worker Port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "vmautomation" {
  name               = "vmautomation-load-balancer"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.sg_lb.id]

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.vmautomation.arn

  port              = 80
  protocol          = "HTTP"

#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}


resource "aws_lb_listener" "worker" {
  load_balancer_arn = aws_lb.vmautomation.arn

  port              = 8000
  protocol          = "HTTP"

#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.worker.arn
  }
}

resource "aws_lb_listener_rule" "redirect_based_on_path" {
  listener_arn = aws_lb_listener.frontend.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*","/api/","/api","/swaggerui/*","/swagger.json"]
    }
  }
}

resource "aws_lb_target_group" "frontend" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
    path                = "/"
  }

  depends_on = [
    aws_lb.vmautomation
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "backend" {
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
    path                = "/api/"
  }

  depends_on = [
    aws_lb.vmautomation
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "worker" {
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
    path                = "/"
  }

  depends_on = [
    aws_lb.vmautomation
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "target" {
  autoscaling_group_name = aws_autoscaling_group.ecs-autoscaling-group.name
  alb_target_group_arn   = aws_lb_target_group.frontend.arn
}


resource "aws_autoscaling_attachment" "backend" {
  autoscaling_group_name = aws_autoscaling_group.ecs-autoscaling-group.name
  alb_target_group_arn   = aws_lb_target_group.backend.arn
}
