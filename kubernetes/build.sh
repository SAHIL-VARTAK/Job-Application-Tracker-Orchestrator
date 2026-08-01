#!/usr/bin/env bash

set -e

CLUSTER_NAME="job-tracker"

echo "=========================================="
echo "Building Docker Images"
echo "=========================================="

echo
echo "[1/4] Building backend image..."
docker build \
    -t job-tracker-backend:latest \
    ./workspace/Job-Application-Tracker

echo
echo "[2/4] Building frontend image..."
docker build \
    -t job-tracker-frontend:latest \
    ./workspace/Job-Application-Tracker-UI

echo
echo "[3/4] Loading backend image into kind..."
kind load docker-image \
    job-tracker-backend:latest \
    --name "${CLUSTER_NAME}"

echo
echo "[4/4] Loading frontend image into kind..."
kind load docker-image \
    job-tracker-frontend:latest \
    --name "${CLUSTER_NAME}"

echo
echo "=========================================="
echo "Images loaded successfully!"
echo "=========================================="