output "cluster_instance_priv_key" {
  value = tls_private_key.cluster_pk.private_key_pem
}

output "lb_dns" {
  value = aws_lb.vmautomation.dns_name
}