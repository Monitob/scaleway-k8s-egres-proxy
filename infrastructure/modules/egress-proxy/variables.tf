variable "env_name" {
  description = "Environment name to use in cluster naming"
  type        = string
}

variable "private_network_id" {
  description = "ID of the private network to attach the cluster to"
  type        = string
}

variable "proxy_node_type" {
  description = "Node type for the proxy VM (e.g., DEV1-M, DEV1-S)"
  type        = string
  default     = "DEV1-M"
}

variable "proxy_image" {
  description = "Image for the proxy VM (e.g., ubuntu_focal)"
  type        = string
  default     = "ubuntu_focal"
}

variable "proxy_zone" {
  description = "Zone for the proxy VM"
  type        = string
  default     = "fr-par-2"
}

variable "proxy_security_group_rules" {
  description = "Security group rules for the proxy VM"
  type = list(object({
    action   = string
    protocol = string
    port     = number
    ip_range = string
  }))
  default = [
    {
      action   = "accept"
      protocol = "tcp"
      port     = 22
      ip_range = "0.0.0.0/0"
    },
    {
      action   = "accept"
      protocol = "icmp"
      port     = -1
      ip_range = "0.0.0.0/0"
    }
  ]
}
