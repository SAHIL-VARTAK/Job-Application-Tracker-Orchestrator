#!/usr/bin/env bash

set -e

echo
echo "========== Cluster =========="
kubectl get nodes

echo
echo "========== Pods =========="
kubectl get pods -n job-tracker

echo
echo "========== Services =========="
kubectl get svc -n job-tracker

echo
echo "========== Ingress =========="
kubectl get ingress -n job-tracker

echo
echo "========== Persistent Volumes =========="
kubectl get pv

echo
echo "========== Persistent Volume Claims =========="
kubectl get pvc -n job-tracker