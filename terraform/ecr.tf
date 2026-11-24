resource "aws_ecr_repository" "moodle" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Name = var.name
  }
}
