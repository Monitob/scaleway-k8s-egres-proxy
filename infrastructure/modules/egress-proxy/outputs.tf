# Proxy VM outputs
output "proxy_public_ip" {
  description = "Public IP address of the proxy VM"
  value       = scaleway_instance_ip.proxy.address
}

output "proxy_private_ip" {
  description = "Private IP address of the proxy VM"
  value       = data.scaleway_instance_private_nic.private_nic.private_ips
}

output "proxy_security_group_id" {
  description = "ID of the proxy VM's security group"
  value       = scaleway_instance_security_group.proxy.id
}
