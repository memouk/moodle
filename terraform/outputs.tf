output "ecr_repository_url" {
  description = "Repositorio de la imagen. El tag que despliega el servicio es latest."
  value       = aws_ecr_repository.moodle.repository_url
}

output "cluster_name" {
  value = aws_ecs_cluster.moodle.name
}

output "service_name" {
  value = aws_ecs_service.moodle.name
}

output "rds_endpoint" {
  value = aws_db_instance.moodle.address
}

output "log_group" {
  value = aws_cloudwatch_log_group.moodle.name
}

output "github_role_arn" {
  description = "Rol que asumen los workflows."
  value       = aws_iam_role.github.arn
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

output "admin_password" {
  description = "Contraseña del usuario admin de Moodle."
  value       = random_password.admin.result
  sensitive   = true
}

output "public_ip_command" {
  description = "La IP pública la asigna Fargate al arrancar la tarea."
  value       = "aws ecs list-tasks --cluster ${aws_ecs_cluster.moodle.name} --service-name ${aws_ecs_service.moodle.name} --query taskArns[0] --output text | xargs -I{} aws ecs describe-tasks --cluster ${aws_ecs_cluster.moodle.name} --tasks {} --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I{} aws ec2 describe-network-interfaces --network-interface-ids {} --query 'NetworkInterfaces[0].Association.PublicIp' --output text"
}
