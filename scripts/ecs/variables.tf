variable "project" {
  type        = string
}

variable "env" {
  type        = string
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  type        = string
}

variable "container_registry_username" {
  type        = string
}

variable "container_registry_password" {
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
}

variable "db_connection_string" {
  type        = string   
}