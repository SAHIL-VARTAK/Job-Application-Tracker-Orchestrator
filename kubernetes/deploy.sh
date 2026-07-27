#!/bin/bash
set -e

kubectl apply -f kubernetes/namespace.yaml

kubectl apply -f kubernetes/backend

kubectl apply -f kubernetes/frontend

kubectl apply -f kubernetes/ingress
