# Scaleway Kubernetes Module

This Terraform module provisions a Scaleway Kubernetes cluster with configurable worker pools and generates a kubeconfig file for cluster access.

## Usage

```hcl
module "kubernetes" {
  source = "./modules/kubernetes"

  env_name                  = "production"
  project_id                = "your-project-id"
  scaleway_region           = "fr-par"
  private_network_id        = "your-private-network-id"
  k8s_version               = "1.30"
  cluster_type              = "kapsule"
  cni                       = "calico"
  worker_node_type          = "DEV1-M"
  worker_zone               = "fr-par-2"
  worker_size               = 3
  worker_min_size           = 3
  worker_max_size           = 10
  root_volume_size_in_gb    = 40
  autoscaling_enabled       = true
  autohealing_enabled       = true
  container_runtime         = "containerd"
  hide_kubeconfig_output    = false
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| env_name | Environment name to use in cluster naming | string | - | yes |
| project_id | Scaleway Project ID | string | - | yes |
| scaleway_region | Scaleway region for resource placement | string | "fr-par" | no |
| k8s_version | Kubernetes version to deploy | string | "1.30" | no |
| cluster_type | Type of Kubernetes cluster (e.g., kapsule) | string | "kapsule" | no |
| cni | CNI plugin for the cluster (e.g., calico, cilium) | string | "calico" | no |
| private_network_id | ID of the private network to attach the cluster to | string | - | yes |
| worker_node_type | Node type for worker pool (e.g., DEV1-M) | string | "DEV1-M" | no |
| worker_zone | Zone for worker nodes | string | "fr-par-2" | no |
| worker_size | Initial number of worker nodes | number | 3 | no |
| worker_min_size | Minimum number of worker nodes | number | 3 | no |
| worker_max_size | Maximum number of worker nodes | number | 10 | no |
| root_volume_size_in_gb | Root volume size in GB for worker nodes | number | 40 | no |
| autoscaling_enabled | Enable autoscaling for the worker pool | bool | true | no |
| autohealing_enabled | Enable autohealing for the worker pool | bool | true | no |
| container_runtime | Container runtime for the worker nodes | string | "containerd" | no |
| hide_kubeconfig_output | Hide the kubeconfig output in local-exec provisioner | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the created Kubernetes cluster |
| cluster_name | Name of the created Kubernetes cluster |
| kubeconfig | Path to the generated kubeconfig file |
| worker_pool_id | ID of the worker pool |

## Dependencies

This module requires:
- Terraform 1.0+
- Scaleway provider
- Network infrastructure (VPC and private network) must be created before using this module

## Notes

- The module creates a kubeconfig.yaml file in the module directory for accessing the cluster
- A 60-second delay is added after cluster creation to allow for proper initialization
- The worker nodes are isolated (no public IP) and connected to the private network
- Automatic upgrades are configured for Sundays at 4 AM