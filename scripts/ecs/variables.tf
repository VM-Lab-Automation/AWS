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

variable "app_attr" {
  type        = string
  default     = "app"   
}

variable "worker_attr" {
  type        = string   
  default     = "worker"
}

variable "password_seed" {
  type        = string
}

variable "workers_count" {
  type        = number
  default     = 1
}

variable "cluster_ami" {
  type        = string
  default     = "ami-01abbd2a80cf7860c"
}