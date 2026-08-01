#!/usr/bin/env bash

set -e

echo "Creating persistent storage..."

kubectl apply -f kubernetes/storage/persistent-volume.yaml
kubectl apply -f kubernetes/storage/persistent-volume-claim.yaml

echo
kubectl get pv
echo
kubectl get pvc -n job-tracker