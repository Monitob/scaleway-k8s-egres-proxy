# Kubernetes Cluster Debugging Guide

This guide provides comprehensive troubleshooting steps for common Kubernetes cluster issues, with a focus on pod scheduling and node affinity problems.

## 🔍 Systematic Debugging Approach

### 1. Initial Assessment
Start by gathering basic information about your cluster state:

```bash
# Check overall cluster health
kubectl cluster-info

# List all namespaces
kubectl get namespaces

# Check node status and capacity
kubectl get nodes -o wide
kubectl describe nodes
```

### 2. Pod Status Investigation
When pods are not running as expected, start with these commands:

```bash
# List all pods across all namespaces
kubectl get pods -A

# Get detailed information about a specific pod
kubectl describe pod <pod-name> -n <namespace>

# Check events for a specific pod
kubectl get events -n <namespace> --field-selector involvedObject.name=<pod-name>
```

### 3. Common Pod States and Troubleshooting

#### 🟡 Pending State
**Symptoms:**
- Pod status shows "Pending"
- No container creation attempts

**Common Causes:**
- Insufficient resources (CPU, memory)
- Node selectors/taints that don't match any nodes  
- PersistentVolume claims that can't be satisfied
- Image pull issues

**Diagnostic Commands:**
```bash
# Check node resources and taints
kubectl describe nodes | grep -A 5 "Allocated resources\|Taints"

# Verify node labels match pod requirements
kubectl get nodes --show-labels

# Check for specific scheduling constraints
kubectl describe pod <pod-name> | grep -A 10 "Node-Selectors\|Tolerations\|Affinity"
```

#### 🔴 CrashLoopBackOff State
**Symptoms:**
- Pod restarts repeatedly
- High restart count in pod status

**Common Causes:**
- Application crashes on startup
- Configuration errors
- Missing dependencies
- Permission issues
- Health check failures

**Diagnostic Commands:**
```bash
# Check logs from the crashing container
kubectl logs <pod-name> -n <namespace> --previous

# Increase log verbosity
kubectl logs <pod-name> -n <namespace> -v=6

# Check the pod's exit code and last state
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "Last State\|Exit Code"
```

#### ⚪ ImagePullBackOff State
**Symptoms:**
- Pod cannot pull container image
- Registry authentication issues

**Common Causes:**
- Incorrect image name or tag
- Private registry without proper credentials
- Network issues preventing image pull
- Image doesn't exist in the registry

**Diagnostic Commands:**
```bash
# Check the exact image being pulled
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Image:"

# Verify image exists in registry (if accessible)
curl -X GET "https://registry.example.com/v2/<image>/tags/list" -H "Authorization: Bearer <token>"
```

### 4. Interactive Debugging

#### Exec into Running Pods
```bash
# Open a shell in the pod
kubectl exec -it <pod-name> -n <namespace> -- sh

# Or bash if available
kubectl exec -it <pod-name> -n <namespace> -- bash
```

#### Useful Commands Inside the Pod
```bash
# Check environment variables
printenv | grep -i <variable-name>

# Check file system and permissions
ls -la /path/to/config
df -h

# Test network connectivity  
ping 8.8.8.8
curl -v http://destination.host:port
nslookup kubernetes.default.svc.cluster.local

# Check processes and ports
ps aux
netstat -tlnp

# Check application-specific logs
tail /var/log/application.log
```

### 5. Network Debugging

#### Connectivity Testing
```bash
# Test connectivity to services
kubectl exec <pod-name> -n <namespace> -- curl -v http://<service-name>

# Test external connectivity
kubectl exec <pod-name> -n <namespace> -- curl -v http://google.com

# Check DNS resolution
kubectl exec <pod-name> -n <namespace> -- nslookup kubernetes.default.svc.cluster.local

# Check network interfaces
kubectl exec <pod-name> -n <namespace> -- ip addr show

# Check routing table
kubectl exec <pod-name> -n <namespace> -- ip route show
```

### 6. Configuration Debugging

#### Verify ConfigMaps and Secrets
```bash
# Check if ConfigMaps are mounted correctly
kubectl exec <pod-name> -n <namespace> -- ls /etc/config

# Check if Secrets are accessible
kubectl exec <pod-name> -n <namespace> -- ls /etc/secret-volume

# Verify environment variables
kubectl exec <pod-name> -n <namespace> -- printenv | grep -i <config-var>

# Check mounted volumes
kubectl exec <pod-name> -n <namespace> -- mount | grep /etc
```

### 7. Resource Monitoring

#### Check Resource Usage
```bash
# Monitor CPU and memory usage
kubectl top pods -n <namespace>
kubectl top pods -n <namespace> --containers=true

# Check pod resource requests and limits
kubectl describe pod <pod-name> -n <namespace> | grep -A 15 "Requests\|Limits"
```

### 8. Multi-tenancy Specific Debugging

#### Verify Node Isolation
```bash
# Check node labels for client-type-a
kubectl get nodes -l node-pool=client-type-a-pool

# Check node labels for client-type-b  
kubectl get nodes -l node-pool=client-type-b-pool

# Verify taints on nodes
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'
```

#### Test Egress Isolation
```bash
# Exec into Client Type A pod (Squid proxy)
kubectl exec -it -n client-type-a deploy/multitenant-demo -- sh

# Test external connectivity (should go through proxy)
curl -v http://ifconfig.me/ip

# Verify proxy environment variables
echo $HTTP_PROXY
echo $HTTPS_PROXY

# Test connectivity to the proxy
curl -v http://172.16.28.8:3128

# Exit
exit

# Exec into Client Type B pod (Load Balancer)
kubectl exec -it -n client-type-b deploy/multitenant-demo -- sh

# Test external connectivity (direct egress)
curl -v http://ifconfig.me/ip

# Verify no proxy settings
env | grep -i proxy

# Exit
exit
```

### 9. Troubleshooting Workflow

#### Step-by-Step Debugging Process
1. **Check pod status and events**
   - `kubectl get pods -n <namespace>`
   - `kubectl describe pod <pod-name> -n <namespace>`

2. **Examine logs**
   - `kubectl logs <pod-name> -n <namespace>`
   - `kubectl logs <pod-name> -n <namespace> --previous`

3. **Verify configuration**
   - Check ConfigMaps, Secrets, and environment variables
   - Verify volume mounts and permissions

4. **Test connectivity**
   - Internal services
   - External endpoints
   - DNS resolution

5. **Check resource constraints**
   - Node capacity vs. pod requests
   - Storage availability
   - Network policies

6. **Interactive debugging**
   - Exec into the pod
   - Run diagnostic commands
   - Check application state

### 10. Common Issues and Solutions

#### Issue: Pod Stuck in Pending State
**Symptoms:**
- Pod status remains "Pending"
- No containers are created

**Solutions:**
1. **Check node selector and tolerations:**
   ```bash
   kubectl describe pod <pod-name> | grep -A 10 "Node-Selectors\|Tolerations"
   ```
   Ensure your nodes have the required labels and no conflicting taints.

2. **Verify sufficient resources:**
   ```bash
   kubectl describe nodes | grep -A 10 "Capacity\|Allocatable"
   ```
   Ensure nodes have enough CPU, memory, and storage for your pod requests.

3. **Check PersistentVolume claims:**
   ```bash
   kubectl get pvc -n <namespace>
   kubectl describe pvc <pvc-name> -n <namespace>
   ```
   Ensure PVCs can be bound to available PersistentVolumes.

#### Issue: Pod Crashes Immediately
**Symptoms:**
- Pod starts but crashes within seconds
- High restart count

**Solutions:**
1. **Check application logs:**
   ```bash
   kubectl logs <pod-name> -n <namespace> --previous
   ```
   Look for application errors, missing dependencies, or configuration issues.

2. **Verify environment variables:**
   ```bash
   kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "Environment"
   ```
   Ensure all required environment variables are set correctly.

3. **Check volume mounts:**
   ```bash
   kubectl describe pod <pod-name> -n <namespace> | grep -A 15 "Volumes"
   ```
   Ensure all required volumes are mounted and accessible.

#### Issue: Image Pull Failed
**Symptoms:**
- Pod status shows "ImagePullBackOff" or "ErrImagePull"
- Cannot download container image

**Solutions:**
1. **Verify image name and tag:**
   ```bash
   kubectl describe pod <pod-name> | grep "Image:"
   ```
   Ensure the image name and tag are correct.

2. **Check registry access:**
   - Verify you have proper credentials for private registries
   - Ensure network connectivity to the registry
   - Check if image pull secrets are properly configured

3. **Verify image existence:**
   ```bash
   # For Docker Hub
   curl -s "https://hub.docker.com/v2/repositories/<image>/tags/<tag>"
   
   # For other registries, use appropriate API
   ```

### 11. Pro Tips for Effective Debugging

1. **Start simple**: Check the pod status and events first
2. **Use labels**: Select pods by labels instead of names
   ```bash
   kubectl logs -l app=multitenant-demo -n client-type-a
   ```
3. **Check the right container**: In multi-container pods
   ```bash
   kubectl logs <pod-name> -n <namespace> -c <container-name>
   ```
4. **Use selectors**: For debugging multiple similar pods
   ```bash
   kubectl logs -l client/type=type-a --all-containers
   ```
5. **Increase verbosity**: When you need more details
   ```bash
   kubectl logs <pod-name> --v=6
   ```

## 🛠 Resolving the Node Affinity Issue

Based on the error message you provided, here's how to resolve the scheduling issue:

### Error Analysis
```
Warning  FailedScheduling   2m3s (x12 over 57m)   default-scheduler   0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector. no new claims to deallocate, preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

This error indicates that:
1. The pod has node affinity/selector requirements
2. No available nodes match these requirements
3. The cluster cannot schedule the pod on any node

### Immediate Steps to Resolve

#### 1. Check the pod's node requirements
```bash
kubectl describe pod <problematic-pod-name> | grep -A 15 "Node-Selectors\|Tolerations\|Affinity"
```

Look for:
- `nodeSelector` with specific labels
- `tolerations` requiring specific taints  
- `nodeAffinity` rules that might be too restrictive

#### 2. Verify available nodes
```bash
# List all nodes with their labels
kubectl get nodes --show-labels

# Check node taints
kubectl describe nodes | grep -A 5 "Taints"
```

#### 3. Common Solutions

**Solution A: Add required labels to existing nodes**
```bash
# If you need nodes with label node-pool=client-type-a-pool
kubectl label nodes <node-name> node-pool=client-type-a-pool

# Or label all nodes
kubectl get nodes -o name | xargs -I {} kubectl label {} node-pool=client-type-a-pool
```

**Solution B: Modify the pod's node requirements**
Edit the deployment or pod specification to:
- Remove or modify node selectors
- Adjust tolerations to match existing taints
- Relax node affinity rules

**Solution C: Add new nodes with required labels**
If this is a production environment and you need proper isolation:
1. Create a new node pool with the required labels
2. Ensure the nodes have the appropriate taints/tolerations
3. Update your cluster configuration

#### 4. Verify the fix
```bash
# After making changes, verify pods are scheduled
kubectl get pods -n client-type-a
kubectl get pods -n client-type-b

# Check that the error is resolved
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -20
```

By following this guide, you should be able to identify and resolve the pod scheduling issue in your cluster.