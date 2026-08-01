#!/usr/bin/env bash

set -e

echo "Creating Kind cluster..."

kind create cluster --config kubernetes/kind-config.yaml

echo
kubectl cluster-info
echo
kubectl get nodes