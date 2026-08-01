#!/usr/bin/env bash

set -e

echo "Installing ingress-nginx..."

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress controller deployment..."

kubectl rollout status deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=180s

echo "Pinning ingress controller to the control-plane node..."

kubectl patch deployment ingress-nginx-controller \
  -n ingress-nginx \
  --type merge \
  --patch-file kubernetes/ingress/controller-patch.yaml

echo "Waiting for patched deployment..."

kubectl rollout status deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=180s

echo "Applying application ingress..."

kubectl apply -f kubernetes/ingress/ingress.yaml

echo
echo "Ingress successfully installed."
echo
kubectl get ingress -n job-tracker