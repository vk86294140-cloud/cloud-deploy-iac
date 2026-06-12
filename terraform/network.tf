# Use the account's default VPC and its subnets to keep the demo free of
# NAT-gateway costs. For production, replace these data sources with a dedicated
# VPC module (private subnets + NAT) and put the tasks in private subnets.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for the public ALB: allow inbound HTTP from anywhere.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "Allow HTTP inbound to the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

# Security group for the Fargate tasks: only the ALB may reach the container port.
resource "aws_security_group" "service" {
  name        = "${var.project_name}-service"
  description = "Allow traffic from the ALB to the service"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "From ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
