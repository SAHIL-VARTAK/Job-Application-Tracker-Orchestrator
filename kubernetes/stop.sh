#!/usr/bin/env bash

set -e

echo "Stopping Job Tracker..."

echo "Removing Ingress..."
kubectl delete -f kubernetes/ingress/ingress.yaml --ignore-not-found=true

echo "Removing Frontend..."
kubectl delete -f kubernetes/frontend --ignore-not-found=true

echo "Removing Backend..."
kubectl delete -f kubernetes/backend --ignore-not-found=true

echo
echo "Job Tracker stopped."