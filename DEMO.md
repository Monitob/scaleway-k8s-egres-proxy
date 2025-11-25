# Multi-tenancy Egress Isolation Demo

This guide demonstrates how our Kubernetes cluster provides isolated egress paths for different client types using two distinct approaches:

1. **Client Type A**: Uses a dedicated Squid proxy instance for egress
2. **Client Type B**: Uses Scaleway Load Balancer for direct egress

## 🎯 Demonstration Goals

The purpose of this demo is to show:
- Complete network isolation between different client types
- Each client type has its own dedicated egress IP
- Traffic from each client type uses its assigned IP
- Different security and routing patterns for different use cases

## 🧪 Test Environment Setup

Before running the demo, ensure:

1. **Squid Proxy Instance** is running at 172.16.28.8:3128
2. **Node Pools** are properly configured:
   - `client-type-a-pool` with taints/tolerations
   - `client-type-b-pool` with taints/tolerations
3. **Network Policies** are applied to enforce isolation

## 🔍 Verification Steps

### 1. Verify Client Type A (Squid Proxy)

#### Check the namespace and pods:
```bash
kubectl get namespaces | grep client-type-a
kubectl get pods -n client-type-a
```

#### Access the application:
```bash
kubectl port-forward svc/multitenant-demo -n client-type-a 8081:8080
```

Visit http://localhost:8081 and verify:
- The proxy configuration shows "Squid Proxy at 172.16.28.8:3128"
- External IP test shows the proxy's public IP (not the node IP)
- Network policy restricts egress to the proxy (port 3128)

#### Test egress path:
```bash
# Exec into the pod
kubectl exec -it -n client-type-a deploy/multitenant-demo -- sh

# Test external connectivity (should go through proxy)
curl -v http://ifconfig.me/ip

# Check environment variables
echo $HTTP_PROXY
echo $HTTPS_PROXY

# Exit
exit
```

### 2. Verify Client Type B (Scaleway Load Balancer)

#### Check the namespace and pods:
```bash
kubectl get namespaces | grep client-type-b
kubectl get pods -n client-type-b
```

#### Access the application:
```bash
kubectl port-forward svc/multitenant-demo-lb -n client-type-b 8082:8080
```

Visit http://localhost:8082 and verify:
- The proxy configuration shows "Direct egress via Scaleway Load Balancer"
- External IP test shows the Load Balancer's public IP
- Network policy allows direct egress to internet

#### Test egress path:
```bash
# Exec into the pod
kubectl exec -it -n client-type-b deploy/multitenant-demo -- sh

# Test external connectivity (direct egress)
curl -v http://ifconfig.me/ip

# Check environment variables (no proxy settings)
env | grep -i proxy

# Exit
exit
```

## 📊 Expected Results

### Client Type A (Squid Proxy)
- **Egress Path**: Pod → Squid Proxy → Internet
- **Public IP**: The public IP of the Squid proxy instance
- **Security**: All traffic inspected and logged by the proxy
- **Use Case**: Clients requiring audit trails and content filtering

### Client Type B (Scaleway Load Balancer)
- **Egress Path**: Pod → Load Balancer → Internet
- **Public IP**: The public IP assigned by the Scaleway Load Balancer
- **Security**: Direct egress with network policy controls
- **Use Case**: Clients requiring high performance and direct connectivity

## 🔄 Multi-tenancy Isolation Verification

### 1. Verify Network Isolation
```bash
# Check that pods from different namespaces cannot communicate directly
kubectl exec -n client-type-a deploy/multitenant-demo -- ping <pod-ip-from-type-b>

# This should fail due to network policies
```

### 2. Verify Node Isolation
```bash
# Check that pods are scheduled on correct nodes
kubectl get pods -n client-type-a -o wide
kubectl get pods -n client-type-b -o wide

# Verify node labels and taints
kubectl get nodes --show-labels
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'
```

### 3. Verify Egress Isolation
The key demonstration is that:

1. **Client Type A** traffic appears to come from the **Squid proxy's public IP**
2. **Client Type B** traffic appears to come from the **Load Balancer's public IP**
3. These are different IP addresses, proving complete egress isolation
4. Each client type uses its own dedicated egress path

## 🛠 Troubleshooting

### Common Issues

#### 1. Pods in Pending State
```bash
# Check events for scheduling issues
kubectl get events -A --field-selector involvedObject.name=<pod-name>

# Verify node selectors and taints
kubectl describe nodes | grep -A 5 "Labels\|Taints"
```

#### 2. Network Connectivity Issues
```bash
# Check network policies
kubectl get networkpolicies -A

# Test connectivity from within pods
kubectl exec -n client-type-a deploy/multitenant-demo -- curl -v http://172.16.28.8:3128
kubectl exec -n client-type-b deploy/multitenant-demo -- curl -v http://google.com
```

#### 3. Service Not Accessible
```bash
# Check service configuration
kubectl get services -A -o wide

# Verify LoadBalancer provisioning
kubectl describe service multitenant-demo-lb -n client-type-b
```

## 📝 Conclusion

This multi-tenancy setup demonstrates two different egress patterns:

1. **Security-focused egress** with Squid proxy for clients needing audit trails and content inspection
2. **Performance-focused egress** with Scaleway Load Balancer for clients needing direct, high-performance connectivity

Both approaches provide complete isolation between client types, ensuring that one client's traffic and security posture does not affect others.