output "db_connection_string" {
  value = module.database.db_connection_string
}

output "cluster_instance_priv_key" {
  value = module.ecs.cluster_instance_priv_key
}