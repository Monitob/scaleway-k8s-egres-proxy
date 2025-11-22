# Architecture Documentation

## Overview

This architecture implements an Egress Proxy pattern for Kubernetes clusters on Scaleway. The solution provides a secure, auditable, and maintainable way for cluster outbound traffic to reach external services while meeting security and compliance requirements.

## Components

### 1. Kubernetes Cluster (Kapsule)

- **Type**: Kapsule managed Kubernetes
- **Network**: Connected to private network (VPC)
- **Nodes**: Worker nodes without public IPs
- **Access**: Private cluster accessible only through internal network
- **Configuration**: Worker nodes configured to use proxy for outbound traffic

### 2. Egress Proxy VM

- **Instance Type**: Small instance (e.g., PLAY2-S or DEV1-S)
- **Image**: Ubuntu LTS
- **Software**: Squid proxy server
- **Network**: Attached to same private network as Kubernetes cluster
- **Public IP**: Flexible IP for internet access
- **Security**: Configured via cloud-init with firewall rules

### 3. Public Gateway (VPC-GW-S)

- **Type**: VPC Gateway Service
- **Function**: Provides internet connectivity to private network
- **Features**: NAT/masquerading, IP routing
- **Location**: In the same private network
- **Connection**: Attached to private network with routing rules

### 4. Security Groups

- **Proxy VM**: Restricts access to SSH and proxy ports
- **Kubernetes Nodes**: No direct internet access
- **Default Policies**: Drop all inbound, accept outbound
- **Rules**: Allow only necessary traffic between components

## Network Topology

```
Internet <----> [Public Gateway] <----> [Proxy VM] <----> [Kubernetes Cluster]
                    |                         |
                    |                         |
               (Flexible IP)          (Private Network)
```

- **Public Gateway**: Acts as the internet gateway for the private network
- **Proxy VM**: Sits between Kubernetes cluster and public gateway
- **Kubernetes Cluster**: Isolated in private network with no direct internet access
- **Traffic Flow**: All outbound traffic from Kubernetes must pass through the proxy

## Traffic Flow

### Outbound Traffic (Kubernetes → Internet)

1. **Application Request**:
   - Application in Kubernetes pod makes HTTP/HTTPS request
   - Request is sent to proxy configured in environment variables

2. **Proxy Routing**:
   - Traffic reaches Proxy VM on port 3128
   - Squid proxy validates the request comes from allowed network
   - Proxy establishes connection to destination

3. **Public Gateway NAT**:
   - Traffic from Proxy VM reaches Public Gateway
   - Gateway performs NAT/masquerading using its public IP
   - Translated traffic is sent to internet destination

4. **Response Handling**:
   - Response reaches Public Gateway
   - Gateway translates back to internal IP
   - Traffic is forwarded to Proxy VM
   - Proxy forwards response to original Kubernetes pod

### Inbound Traffic (Internet → Kubernetes)

In this architecture, there is no direct inbound traffic to Kubernetes pods. All external access must go through appropriate ingress controllers or API gateways that are properly secured.

## Configuration Management

### Cloud-init Configuration

The Proxy VM is configured using cloud-init with the following process:

1. **Package Installation**:
   - Updates package list
   - Installs Squid proxy server

2. **Squid Configuration**:
   - Listens on port 3128
   - Allows only traffic from Kubernetes private network
   - Denies all other access
   - Disables caching (routing only)
   - Hides internal IPs from external services

3. **Firewall Configuration**:
   - Allows SSH access (port 22)
   - Allows proxy traffic (port 3128)
   - Enables UFW firewall

4. **Service Restart**:
   - Restarts Squid service to apply configuration

### Terraform Modules

The architecture is implemented using reusable Terraform modules:

- **egress-proxy module**:
  - Creates Proxy VM
  - Configures security group
  - Applies cloud-init configuration
  - Outputs public and private IPs

- **kubernetes module**:
  - Creates Kapsule cluster
  - Configures worker pools
  - Generates kubeconfig
  - Manages cluster lifecycle

## Security Considerations

### Network Security

- **Isolation**: Kubernetes cluster is completely isolated from direct internet access
- **Controlled Access**: Only the proxy VM can initiate outbound connections
- **Whitelist Model**: Only connections to pre-approved destinations are allowed
- **Internal Communication**: All traffic between components stays within private network

### Access Control

- **SSH Access**: Restricted to authorized IPs via security groups
- **Proxy Access**: Limited to Kubernetes private network
- **Least Privilege**: Each component has only the permissions it needs
- **Audit Trail**: All outbound connections are logged by the proxy

### Data Privacy

- **IP Masking**: Internal cluster IPs are hidden from external services
- **Traffic Inspection**: All outbound traffic can be monitored and logged
- **No Direct Exposure**: Worker nodes are never directly exposed to internet
- **Secure Configuration**: Sensitive data is managed through Terraform variables

## Operational Benefits

### Reliability

- **Single Point of Failure**: The proxy VM is a single point, but can be made highly available
- **Predictable Performance**: Traffic patterns are consistent and predictable
- **Easy Troubleshooting**: All outbound traffic is visible at the proxy
- **Consistent Configuration**: Cloud-init ensures identical setup every time

### Maintainability

- **Easy Updates**: Proxy software and configuration can be updated independently
- **Scalability**: Proxy VM can be upgraded as traffic increases
- **Monitoring**: Centralized logging and monitoring at the proxy
- **Backup and Recovery**: VM images can be backed up and restored

### Cost Efficiency

- **Optimized Resources**: Small proxy VM for routing only
- **No Premium Features**: Uses standard Scaleway services
- **Efficient Bandwidth**: Traffic optimization through proxy
- **Predictable Costs**: Fixed costs for proxy VM and gateway

## Use Cases

### 1. External API Integration

When applications need to call external APIs:

- Configure HTTP_PROXY environment variable
- All API calls route through the proxy
- External service sees requests from proxy's public IP
- Traffic is logged and auditable

### 2. Package Repository Access

For accessing external package repositories:

- Configure package managers to use proxy
- npm, pip, apt-get, etc. can access external repositories
- All downloads are routed through the proxy
- Whitelisting only required repositories

### 3. Database Replication

For connecting to external database services:

- Configure database connection to use proxy
- Replication traffic flows through proxy
- Secure and auditable database connections
- No direct database exposure

### 4. Monitoring and Alerting

For external monitoring services:

- Configure monitoring agents to use proxy
- Health checks and metrics sent through proxy
- Alert notifications routed externally
- Complete visibility into outbound monitoring traffic

## Implementation Details

### Variable Configuration

The architecture is configured through Terraform variables:

- `env_name`: Environment identifier
- `private_network_id`: VPC network for all components
- `proxy_node_type`: Instance size for proxy VM
- `proxy_image`: OS image for proxy VM
- `proxy_zone`: Availability zone
- `private_network_cidr`: Allowed network range for proxy

### Dependencies and Ordering

The components are created in a specific order to ensure proper dependencies:

1. **Public Gateway**: Created first as network foundation
2. **Proxy VM**: Created next, attached to private network
3. **Kubernetes Cluster**: Created last, depends on network setup

This ensures all network connections are properly established before workloads are deployed.

### Outputs

The configuration provides useful outputs:

- `proxy_public_ip`: Public IP for whitelisting
- `proxy_private_ip`: Internal IP for Kubernetes configuration
- `cluster_id`: Kubernetes cluster identifier
- `kubeconfig`: Path to kubeconfig file for cluster access

These outputs make it easy to integrate with other systems and automation.

## Best Practices

### Security

- Regularly update proxy VM and Squid software
- Monitor proxy logs for suspicious activity
- Use strong SSH key authentication
- Implement intrusion detection
- Regular security audits

### Monitoring

- Monitor proxy performance and load
- Set up alerts for high traffic or errors
- Log all outbound connections
- Monitor public gateway metrics
- Track resource utilization

### Maintenance

- Plan for proxy VM maintenance windows
- Implement backup strategy for proxy configuration
- Test failover procedures
- Document configuration changes
- Keep Terraform code up to date

### Scaling

- Monitor proxy VM resource usage
- Upgrade instance size as needed
- Consider multiple proxy VMs with load balancing for high traffic
- Implement connection pooling
- Optimize Squid configuration for performance

This comprehensive architecture provides a robust foundation for secure and reliable Kubernetes deployments on Scaleway.