variable "aws_region" {
  description = "Región. La misma de las entregas anteriores."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil de AWS. Null usa la cadena por defecto, que es la de GitHub Actions."
  type        = string
  default     = null
}

variable "name" {
  description = "Prefijo de los recursos."
  type        = string
  default     = "moodle"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "task_cpu" {
  description = "CPU de Fargate. 1024 es 1 vCPU."
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memoria de la tarea en MB. 512 no alcanza para instalar Moodle."
  type        = number
  default     = 2048
}

variable "db_name" {
  type    = string
  default = "moodle"
}

variable "db_username" {
  type    = string
  default = "moodle"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_engine_version" {
  description = "Moodle 6.0dev aplica el bloque 5.3 de environment.xml, que exige MariaDB >= 11.4.0. Con 10.11 el instalador CLI termina en error."
  type        = string
  default     = "11.4.13"
}

variable "moodle_fullname" {
  type    = string
  default = "Moodle ITM"
}

variable "moodle_shortname" {
  type    = string
  default = "itm"
}

variable "admin_email" {
  type    = string
  default = "admin@example.com"
}

variable "github_repository" {
  description = "Repositorio autorizado a asumir el rol de Actions, en formato propietario/nombre."
  type        = string
  default     = "memouk/moodle"
}
