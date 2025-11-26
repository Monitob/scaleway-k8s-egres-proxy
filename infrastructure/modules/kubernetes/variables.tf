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

variable "worker_zone_1" {
  description = "Zone for worker nodes"
  type        = string
  default     = "fr-par-1"
}

variable "worker_zone_2" {
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

# Client Type A Worker Pool Variables
variable "client_type_a_node_type" {
  description = "Node type for Client Type A worker pool (e.g., DEV1-M)"
  type        = string
  default     = "DEV1-M"
}

variable "client_type_a_size" {
  description = "Initial number of worker nodes for Client Type A"
  type        = number
  default     = 2
}

variable "client_type_a_min_size" {
  description = "Minimum number of worker nodes for Client Type A"
  type        = number
  default     = 1
}

variable "client_type_a_max_size" {
  description = "Maximum number of worker nodes for Client Type A"
  type        = number
  default     = 5
}

# Client Type B Worker Pool Variables
variable "client_type_b_node_type" {
  description = "Node type for Client Type B worker pool (e.g., DEV1-M)"
  type        = string
  default     = "DEV1-M"
}

variable "client_type_b_size" {
  description = "Initial number of worker nodes for Client Type B"
  type        = number
  default     = 2
}

variable "client_type_b_min_size" {
  description = "Minimum number of worker nodes for Client Type B"
  type        = number
  default     = 1
}

variable "client_type_b_max_size" {
  description = "Maximum number of worker nodes for Client Type B"
  type        = number
  default     = 5
}
