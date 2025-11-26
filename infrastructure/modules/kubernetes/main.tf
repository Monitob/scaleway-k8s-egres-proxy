# Kubernetes Module
# This module provisions a Scaleway Kubernetes cluster with worker pools and generates kubeconfig

# Kubernetes Cluster Resource
resource "scaleway_k8s_cluster" "k8s" {
  timeouts {
    create = "60m"
  }

  project_id                  = var.project_id
  name                        = "cluster-${var.env_name}"
  version                     = var.k8s_version
  region                      = var.scaleway_region
  cni                         = var.cni
  type                        = var.cluster_type
  private_network_id          = var.private_network_id
  delete_additional_resources = false

  autoscaler_config {
    disable_scale_down              = false
    scale_down_delay_after_add      = "5m"
    estimator                       = "binpacking"
    expander                        = "random"
    ignore_daemonsets_utilization   = true
    balance_similar_node_groups     = true
    expendable_pods_priority_cutoff = -5
  }

  auto_upgrade {
    enable                        = true
    maintenance_window_day        = "sunday"
    maintenance_window_start_hour = 4
  }
}

# Wait for cluster to stabilize
resource "time_sleep" "wait_for_gtw" {
  create_duration = "60s"
}

# Kubernetes Worker Pools

# Dedicated worker pool for Client Type A (Squid Proxy)
resource "scaleway_k8s_pool" "client_type_a_pool" {
  timeouts {
    create = "60m"
  }

  depends_on             = [time_sleep.wait_for_gtw]
  name                   = "client-type-a-pool"
  public_ip_disabled     = true
  cluster_id             = scaleway_k8s_cluster.k8s.id
  node_type              = var.client_type_a_node_type
  zone                   = var.worker_zone_1
  size                   = var.client_type_a_size
  min_size               = var.client_type_a_min_size
  max_size               = var.client_type_a_max_size
  autoscaling            = var.autoscaling_enabled
  autohealing            = var.autohealing_enabled
  container_runtime      = var.container_runtime
  root_volume_size_in_gb = var.root_volume_size_in_gb

  # Tags will be synchronized to Kubernetes labels and taints
  tags = [
    "pool=client-type-a",
    "k8s.scaleway.com/pool=client-type-a",
    "noprefix=pool=client-type-a",
    "taint=noprefix=node-role.kubernetes.io/client-a=dedicated:NoSchedule"
  ]
}

# Dedicated worker pool for Client Type B (Load Balancer)
resource "scaleway_k8s_pool" "client_type_b_pool" {
  timeouts {
    create = "60m"
  }

  depends_on             = [time_sleep.wait_for_gtw]
  name                   = "client-type-b-pool"
  public_ip_disabled     = true
  cluster_id             = scaleway_k8s_cluster.k8s.id
  node_type              = var.client_type_b_node_type
  zone                   = var.worker_zone_2
  size                   = var.client_type_b_size
  min_size               = var.client_type_b_min_size
  max_size               = var.client_type_b_max_size
  autoscaling            = var.autoscaling_enabled
  autohealing            = var.autohealing_enabled
  container_runtime      = var.container_runtime
  root_volume_type       = "sbs_5k"
  root_volume_size_in_gb = var.root_volume_size_in_gb

  # Tags will be synchronized to Kubernetes labels and taints
  tags = [
    "pool=client-type-b",
    "k8s.scaleway.com/pool=client-type-b",
    "noprefix=pool=client-type-b-pool",
    "taint=noprefix=node-role.kubernetes.io/client-b=dedicated:NoSchedule"
  ]
}

# Generate Kubeconfig
resource "null_resource" "kubeconfig" {
  depends_on = [
    scaleway_k8s_pool.client_type_a_pool,
    scaleway_k8s_pool.client_type_b_pool
  ]

  triggers = {
    host                   = scaleway_k8s_cluster.k8s.kubeconfig[0].host
    token                  = scaleway_k8s_cluster.k8s.kubeconfig[0].token
    cluster_ca_certificate = scaleway_k8s_cluster.k8s.kubeconfig[0].cluster_ca_certificate
  }

  provisioner "local-exec" {
    environment = {
      HIDE_OUTPUT = var.hide_kubeconfig_output
    }
    command = <<-EOT
    cat<<EOF>kubeconfig.yaml
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: ${self.triggers.cluster_ca_certificate}
        server: ${self.triggers.host}
      name: ${scaleway_k8s_cluster.k8s.name}
    contexts:
    - context:
        cluster: ${scaleway_k8s_cluster.k8s.name}
        user: admin
      name: admin@${scaleway_k8s_cluster.k8s.name}
    current-context: admin@${scaleway_k8s_cluster.k8s.name}
    kind: Config
    preferences: {}
    users:
    - name: admin
      user:
        token: ${self.triggers.token}
    EOT
  }
}
