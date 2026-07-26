#!/usr/bin/env bash

set -e

BACKEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker.git"
FRONTEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker-UI.git"

WORKSPACE_DIR="workspace"

BACKEND_NAME="Job-Application-Tracker"
FRONTEND_NAME="Job-Application-Tracker-UI"

BACKEND_DIR="$WORKSPACE_DIR/$BACKEND_NAME"
FRONTEND_DIR="$WORKSPACE_DIR/$FRONTEND_NAME"

show_help() {
    cat << EOF
Job Application Tracker Orchestrator

Usage:
  ./orchestrator.sh <command>

Commands:
  launch     Clone repositories and start the application
  stop       Stop all running containers
  update     Pull latest changes and rebuild
  logs       View application logs
  health     Check application health
  clean      Remove containers and Docker resources
  help       Show this help message
EOF
}

check_prerequisites() {
    command -v git >/dev/null 2>&1 || {
        echo "❌ Git is not installed."
        exit 1
    }

    command -v docker >/dev/null 2>&1 || {
        echo "❌ Docker is not installed."
        exit 1
    }

    docker info >/dev/null 2>&1 || {
        echo "❌ Docker is not running."
        exit 1
    }
}

create_workspace() {
    mkdir -p "$WORKSPACE_DIR"
}

clone_repository() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="$3"

    if [[ -d "$target_dir/.git" ]]; then
        echo "✓ $repo_name already exists."
        return
    fi

    echo "Cloning $repo_name..."
    git clone "$repo_url" "$target_dir"
    echo "✓ $repo_name cloned successfully."
}

launch() {
    check_prerequisites

    echo "WORKSPACE_DIR = $WORKSPACE_DIR"
echo "BACKEND_DIR   = $BACKEND_DIR"
echo "FRONTEND_DIR  = $FRONTEND_DIR"

    create_workspace

    clone_repository \
        "$BACKEND_REPO" \
        "$BACKEND_DIR" \
        "$BACKEND_NAME"

    clone_repository \
        "$FRONTEND_REPO" \
        "$FRONTEND_DIR" \
        "$FRONTEND_NAME"

    echo
    echo "✓ All repositories are ready."
}

stop() {
    echo "Stop command coming soon..."
}

update() {
    echo "Update command coming soon..."
}

logs() {
    echo "Logs command coming soon..."
}

health() {
    echo "Health command coming soon..."
}

clean() {
    echo "Clean command coming soon..."
}

case "${1:-help}" in
    launch)
        launch
        ;;
    stop)
        stop
        ;;
    update)
        update
        ;;
    logs)
        logs
        ;;
    health)
        health
        ;;
    clean)
        clean
        ;;
    help)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac