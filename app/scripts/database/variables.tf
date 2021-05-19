variable "allocated_size" {
  type = number
}

variable "engine_type" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "username" {
  type = string
}

variable "password_seed" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_security_group_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}