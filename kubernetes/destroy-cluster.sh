#!/usr/bin/env bash

set -e

echo "Deleting Kind cluster..."

kind delete cluster --name job-tracker

echo
echo "Cluster deleted."