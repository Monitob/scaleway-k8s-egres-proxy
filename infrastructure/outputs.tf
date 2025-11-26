# Module Outputs
output "cluster_id" {
  description = "ID of the created Kubernetes cluster"
  value       = module.kubernetes.cluster_id
}

output "cluster_name" {
  description = "Name of the created Kubernetes cluster"
  value       = module.kubernetes.cluster_name
}

output "kubeconfig" {
  description = "Path to the generated kubeconfig file"
  value       = module.kubernetes.kubeconfig
}

output "worker_pool_a_id" {
  description = "ID A of the worker pool"
  value       = module.kubernetes.client_type_a_pool_id
}

output "worker_pool_b_id" {
  description = "ID B of the worker pool"
  value       = module.kubernetes.client_type_b_pool_id
}

# Egress Proxy Outputs
output "proxy_public_ip" {
  description = "Public IP address of the proxy VM"
  value       = module.egress_proxy.proxy_public_ip
}

# Public Gateway Outputs
output "gateway_id" {
  description = "ID of the public gateway"
  value       = scaleway_vpc_public_gateway.main.id
}

output "gateway_name" {
  description = "Name of the public gateway"
  value       = scaleway_vpc_public_gateway.main.name
}

output "gateway_type" {
  description = "Type of the public gateway"
  value       = scaleway_vpc_public_gateway.main.type
}
