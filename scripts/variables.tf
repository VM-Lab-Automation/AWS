variable "database" {
  type = object({
    db_name = string
    username = string
    password_seed = string
    allocated_size = number
    engine_type = string
    instance_class = string
  })
}

variable "project" {
  type        = string
}

variable "env" {
  type = string
}

variable "location" {
  type = string
}

variable "shared_credentials_file" {
  type = string
}