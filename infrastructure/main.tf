# Public Gateway Resource
resource "scaleway_vpc_public_gateway" "main" {
  name = "gateway-${var.env_name}"
  type = "VPC-GW-S"
  tags = ["${var.env_name}", "terraform"]
  zone = var.worker_zone
}

# Attach public gateway to private network with proper routing
resource "scaleway_vpc_gateway_network" "main" {
  gateway_id         = scaleway_vpc_public_gateway.main.id
  private_network_id = var.private_network_id
  enable_masquerade  = true
  ipam_config {
    push_default_route = true
  }
  depends_on = [scaleway_vpc_public_gateway.main]
}

resource "time_sleep" "gateway_attachment" {
  depends_on      = [scaleway_vpc_gateway_network.main]
  create_duration = "60s"
}

# Egress Proxy Module
module "egress_proxy" {
  source = "./modules/egress-proxy"

  env_name                   = var.env_name
  private_network_id         = var.private_network_id
  proxy_node_type            = var.proxy_node_type
  proxy_image                = var.proxy_image
  proxy_zone                 = var.proxy_zone
  proxy_security_group_rules = var.proxy_security_group_rules
  # Wait for private network to be ready
  depends_on = [time_sleep.gateway_attachment]
}

# Kubernetes Module
module "kubernetes" {
  source = "./modules/kubernetes"

  env_name               = var.env_name
  project_id             = var.project_id
  scaleway_region        = var.scaleway_region
  k8s_version            = var.k8s_version
  cluster_type           = var.cluster_type
  cni                    = var.cni
  private_network_id     = var.private_network_id
  worker_node_type       = var.worker_node_type
  worker_zone            = var.worker_zone
  worker_min_size        = var.worker_min_size
  worker_max_size        = var.worker_max_size
  worker_size            = var.worker_size
  root_volume_size_in_gb = var.root_volume_size_in_gb
  autoscaling_enabled    = var.autoscaling_enabled
  autohealing_enabled    = var.autohealing_enabled
  container_runtime      = var.container_runtime
  hide_kubeconfig_output = var.hide_kubeconfig_output
  # Wait for the gateway network to be ready before creating the cluster
  depends_on = [time_sleep.gateway_attachment]
}
