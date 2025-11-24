# Remove finalizers if necessary
kubectl patch gitrepository flux-system -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl patch kustomization flux-system -n flux-system -p '{"metadata":{"finalizers":null}}' --type=merge

# Delete the flux-system namespace
kubectl delete namespace flux-system

