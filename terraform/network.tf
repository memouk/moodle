resource "aws_vpc" "moodle" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "moodle" {
  vpc_id = aws_vpc.moodle.id

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.moodle.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.moodle.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.moodle.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.moodle.id
  }

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs"
  description = "HTTP publico hacia la tarea de Moodle."
  vpc_id      = aws_vpc.moodle.id

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

  tags = {
    Name = "${var.name}-ecs"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "MariaDB solo desde la tarea de Moodle."
  vpc_id      = aws_vpc.moodle.id

  ingress {
    description     = "MariaDB desde ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds"
  }
}
