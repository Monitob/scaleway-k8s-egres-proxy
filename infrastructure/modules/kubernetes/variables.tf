variable "env_name" {
  description = "Environment name to use in cluster naming"
  type        = string
}

variable "project_id" {
  description = "Scaleway Project ID"
  type        = string
}

variable "scaleway_region" {
  description = "Scaleway region for resource placement"
  type        = string
  default     = "fr-par"
}

variable "k8s_version" {
  description = "Kubernetes version to deploy"
  type        = string
  default     = "1.30"
}

variable "cluster_type" {
  description = "Type of Kubernetes cluster (e.g., kapsule)"
  type        = string
  default     = "kapsule"
}

variable "cni" {
  description = "CNI plugin for the cluster (e.g., calico, cilium)"
  type        = string
  default     = "calico"
}

variable "private_network_id" {
  description = "ID of the private network to attach the cluster to"
  type        = string
}

variable "worker_node_type" {
  description = "Node type for worker pool (e.g., DEV1-M)"
  type        = string
  default     = "DEV1-M"
}

variable "worker_zone" {
  description = "Zone for worker nodes"
  type        = string
  default     = "fr-par-2"
}

variable "worker_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 3
}

variable "worker_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10
}

variable "worker_size" {
  description = "Initial number of worker nodes"
  type        = number
  default     = 3
}

variable "root_volume_size_in_gb" {
  description = "Root volume size in GB for worker nodes"
  type        = number
  default     = 40
}

variable "autoscaling_enabled" {
  description = "Enable autoscaling for the worker pool"
  type        = bool
  default     = true
}

variable "autohealing_enabled" {
  description = "Enable autohealing for the worker pool"
  type        = bool
  default     = true
}

variable "container_runtime" {
  description = "Container runtime for the worker nodes"
  type        = string
  default     = "containerd"
}

variable "hide_kubeconfig_output" {
  description = "Hide the kubeconfig output in local-exec provisioner"
  type        = bool
  default     = false
}
