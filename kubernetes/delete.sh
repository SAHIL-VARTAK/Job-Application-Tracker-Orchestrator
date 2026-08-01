#!/usr/bin/env bash

set -e

echo "Deleting Job Tracker..."

./kubernetes/stop.sh

echo
echo "Removing Persistent Storage..."

kubectl delete -f kubernetes/storage/persistent-volume-claim.yaml \
    --ignore-not-found=true

kubectl delete -f kubernetes/storage/persistent-volume.yaml \
    --ignore-not-found=true

echo
echo "Removing Namespace..."

kubectl delete -f kubernetes/namespace.yaml \
    --ignore-not-found=true

echo
echo "All Kubernetes resources deleted."