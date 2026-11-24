resource "random_password" "db" {
  length  = 24
  special = false
}

resource "random_password" "admin" {
  length  = 20
  special = false
}

resource "aws_db_subnet_group" "moodle" {
  name       = var.name
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = var.name
  }
}

resource "aws_db_instance" "moodle" {
  identifier                 = var.name
  engine                     = "mariadb"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  storage_type               = "gp3"
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = random_password.db.result
  db_subnet_group_name       = aws_db_subnet_group.moodle.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 1
  delete_automated_backups   = true
  skip_final_snapshot        = true
  deletion_protection        = false
  auto_minor_version_upgrade = true
  apply_immediately          = true

  tags = {
    Name = var.name
  }
}
