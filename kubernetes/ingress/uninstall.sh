#!/usr/bin/env bash

set -e

echo "Removing ingress-nginx..."

kubectl delete -f kubernetes/ingress/ingress.yaml --ignore-not-found=true

kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo
echo "Ingress controller removed."