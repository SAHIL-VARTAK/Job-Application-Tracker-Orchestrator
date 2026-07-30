#!/usr/bin/env bash

set -e

echo "Deploying Job Tracker..."

kubectl apply -f kubernetes/namespace.yaml

./kubernetes/storage/install.sh

kubectl apply -f kubernetes/backend

kubectl apply -f kubernetes/frontend

./kubernetes/ingress/install.sh

echo
echo "Deployment completed successfully."