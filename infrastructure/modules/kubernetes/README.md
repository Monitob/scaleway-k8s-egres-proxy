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
| main_worker_pool_id | ID of the main worker pool |
| client_type_a_pool_id | ID of the Client Type A worker pool |
| client_type_b_pool_id | ID of the Client Type B worker pool |

## Dependencies

This module requires:
- Terraform 1.0+
- Scaleway provider
- Network infrastructure (VPC and private network) must be created before using this module

## Features

### Multi-tenancy Support
This module supports multi-tenancy with dedicated worker pools for different client types using Scaleway's tag synchronization:

1. **Main Worker Pool**: General workloads
   - Node type: Configurable via `worker_node_type`
   - Tags: `pool=main`
   - Kubernetes Labels: `k8s.scaleway.com/pool=main` and `pool=main`
   - Use case: Shared services and applications

2. **Client Type A Pool**: Squid Proxy egress
   - Node type: Configurable via `client_type_a_node_type`
   - Tags: `pool=client-type-a` and `taint=noprefix=node-role.kubernetes.io/client-a=dedicated:NoSchedule`
   - Kubernetes Labels: `k8s.scaleway.com/pool=client-type-a` and `pool=client-type-a`
   - Kubernetes Taint: `node-role.kubernetes.io/client-a=dedicated:NoSchedule`
   - Use case: Clients requiring audit trails and content filtering

3. **Client Type B Pool**: Load Balancer egress
   - Node type: Configurable via `client_type_b_node_type`
   - Tags: `pool=client-type-b` and `taint=noprefix=node-role.kubernetes.io/client-b=dedicated:NoSchedule`
   - Kubernetes Labels: `k8s.scaleway.com/pool=client-type-b` and `pool=client-type-b`
   - Kubernetes Taint: `node-role.kubernetes.io/client-b=dedicated:NoSchedule`
   - Use case: Clients requiring high performance and direct connectivity

### Node Isolation with Scaleway Tags
Each worker pool uses Scaleway's native tag synchronization for complete isolation:

- **Tag Synchronization**: Scaleway automatically converts instance tags to Kubernetes labels and taints
- **Label Format**: Tags of the form `foo=bar` become `k8s.scaleway.com/foo=bar` labels
- **Non-prefixed Labels**: Tags with `noprefix=` prefix create labels without the `k8s.scaleway.com/` prefix
- **Taint Format**: Tags of the form `taint=foo=bar:Effect` become taints with the specified effect
- **Non-prefixed Taints**: Tags with `taint=noprefix=` prefix create taints without the `k8s.scaleway.com/` prefix
- **Automatic Cleanup**: When tags are removed from instances, corresponding labels are automatically removed (except for non-prefixed ones)

This approach leverages Scaleway's native capabilities for reliable and automatic synchronization between infrastructure tags and Kubernetes node properties.

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
  
  # Client Type A Pool (Squid Proxy)
  client_type_a_node_type   = "DEV1-M"
  client_type_a_size        = 2
  client_type_a_min_size    = 1
  client_type_a_max_size    = 5
  
  # Client Type B Pool (Load Balancer)
  client_type_b_node_type   = "PRO-A-12"
  client_type_b_size        = 2
  client_type_b_min_size    = 1
  client_type_b_max_size    = 5

  root_volume_size_in_gb    = 40
  autoscaling_enabled       = true
  autohealing_enabled       = true
  container_runtime         = "containerd"
  hide_kubeconfig_output    = false
}
```

## Notes

- The module creates a kubeconfig.yaml file in the module directory for accessing the cluster
- A 60-second delay is added after cluster creation to allow for proper initialization
- The worker nodes are isolated (no public IP) and connected to the private network
- Automatic upgrades are configured for Sundays at 4 AM
+- Multi-tenancy support uses Scaleway's tag synchronization for reliable node configuration
+- Automatic tag-to-label/taint conversion ensures consistency between infrastructure and Kubernetes
+- Non-prefixed taints allow for standard Kubernetes taints like node-role.kubernetes.io