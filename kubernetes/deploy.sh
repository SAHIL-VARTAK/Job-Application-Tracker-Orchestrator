#!/bin/bash
set -e

kubectl apply -f namespace.yaml
kubectl apply -f backend/pvc.yaml
kubectl apply -f backend/deployment.yaml
kubectl apply -f backend/service.yaml
kubectl apply -f frontend/deployment.yaml
kubectl apply -f frontend/service.yaml
kubectl apply -f ingress/ingress.yaml
