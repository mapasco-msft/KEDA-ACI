#!/bin/bash

# Prevent replication
kubectl delete replicaset --all

# Delete services
kubectl delete svc --all

# Delete pods
kubectl delete pods --all

# Delete deployments
kubectl delete deployment --all

# Delete Daemonsets
kubectl delete daemonset --all

kubectl patch crd/scaledobjects.keda.k8s.io -p '{"metadata":{"finalizers":[]}}' --type=merge
# Remove CustomResourceDefinitions
kubectl delete crd --all 

# Remove ServiceAccounts
kubectl delete sa $(kubectl get sa -o custom-columns=:.metadata.name)
