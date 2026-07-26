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
  launch                  Clone repositories and start the application
  update                  Update repositories and restart the application
  stop                    Stop the application
  logs [backend|frontend] View application logs
  health                  Check application health
  clean                   Remove cloned repositories and Docker resources
  help                    Show this help message
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

    docker compose version >/dev/null 2>&1 || {
        echo "❌ Docker Compose is not available."
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

update_repositories() {
    echo
    echo "Updating repositories..."

    for repo_dir in "$BACKEND_DIR" "$FRONTEND_DIR"; do
        if [[ ! -d "$repo_dir/.git" ]]; then
            echo "❌ Repository not found: $repo_dir"
            echo "Run './orchestrator.sh launch' first."
            exit 1
        fi

        repo_name=$(basename "$repo_dir")

        echo
        echo "Updating $repo_name..."

        (
            cd "$repo_dir" || exit 1

            git fetch --all

            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

            git pull origin "$CURRENT_BRANCH"
        )

        echo "✓ $repo_name updated."
    done
}

start_application() {
    echo
    echo "Building Docker images..."

    docker compose build

    echo
    echo "Starting containers..."

    docker compose up -d
}

restart_application() {
    echo
    echo "Stopping containers..."

    docker compose down

    echo
    echo "Rebuilding images..."

    docker compose build

    echo
    echo "Starting containers..."

    docker compose up -d
}

launch() {
    check_prerequisites

    create_workspace

    clone_repository \
        "$BACKEND_REPO" \
        "$BACKEND_DIR" \
        "$BACKEND_NAME"

    clone_repository \
        "$FRONTEND_REPO" \
        "$FRONTEND_DIR" \
        "$FRONTEND_NAME"

    start_application

    echo
    echo "========================================="
    echo " Job Application Tracker is running!"
    echo "========================================="
    echo
    echo "Frontend : http://localhost:5173"
    echo "Backend  : http://localhost:8080"
    echo "Swagger  : http://localhost:8080/swagger-ui/index.html"
}

stop() {
    check_prerequisites

    echo
    echo "Stopping Job Application Tracker..."

    docker compose down

    echo
    echo "========================================="
    echo " Job Application Tracker stopped."
    echo "========================================="
}

update() {
    check_prerequisites

    update_repositories

    restart_application

    echo
    echo "========================================="
    echo " Job Application Tracker updated!"
    echo "========================================="
    echo
    echo "Frontend : http://localhost:5173"
    echo "Backend  : http://localhost:8080"
    echo "Swagger  : http://localhost:8080/swagger-ui/index.html"
}

logs() {
    check_prerequisites

    case "${2:-all}" in
        backend)
            docker compose logs -f backend
            ;;
        frontend)
            docker compose logs -f frontend
            ;;
        all)
            docker compose logs -f
            ;;
        *)
            echo "Invalid service. Use: backend, frontend, or omit for all."
            exit 1
            ;;
    esac
}

health() {
    check_prerequisites

    local overall_status=0

    echo
    echo "========================================="
    echo " Application Health"
    echo "========================================="
    echo

    echo "Docker"

    if docker info >/dev/null 2>&1; then
        echo "  ✓ Docker daemon is running"
    else
        echo "  ✗ Docker daemon is not running"
        overall_status=1
    fi

    echo
    echo "Containers"

    if docker compose ps --status running | grep -q "backend"; then
        echo "  ✓ Backend container is running"
    else
        echo "  ✗ Backend container is not running"
        overall_status=1
    fi

    if docker compose ps --status running | grep -q "frontend"; then
        echo "  ✓ Frontend container is running"
    else
        echo "  ✗ Frontend container is not running"
        overall_status=1
    fi

    echo
    echo "Endpoints"

    if curl --silent --fail http://localhost:8080/api/applications >/dev/null; then
        echo "  ✓ Backend API      http://localhost:8080/api/applications"
    else
        echo "  ✗ Backend API      Unreachable"
        overall_status=1
    fi

    if curl --silent --fail http://localhost:8080/swagger-ui/index.html >/dev/null; then
        echo "  ✓ Swagger UI       http://localhost:8080/swagger-ui/index.html"
    else
        echo "  ✗ Swagger UI       Unreachable"
        overall_status=1
    fi

    if curl --silent --fail http://localhost:5173 >/dev/null; then
        echo "  ✓ Frontend         http://localhost:5173"
    else
        echo "  ✗ Frontend         Unreachable"
        overall_status=1
    fi

    echo
    echo "Overall Status"

    if [[ $overall_status -eq 0 ]]; then
        echo "  ✓ Application is healthy"
        return 0
    else
        echo "  ✗ Application is unhealthy"
        return 1
    fi
}

clean() {
    check_prerequisites

    echo
    echo "========================================="
    echo " Clean Workspace"
    echo "========================================="
    echo
    echo "This will remove:"
    echo "  • Cloned repositories"
    echo "  • Docker containers"
    echo "  • Docker images"
    echo "  • SQLite database"
    echo

    read -rp "Continue? (Y/N): " response

    case "$response" in
        [yY]|[yY][eE][sS])
            ;;
        *)
            echo
            echo "Clean operation cancelled."
            return
            ;;
    esac

    echo
    echo "Stopping containers..."
    docker compose down --rmi local

    echo "Removing cloned repositories..."
    rm -rf "$BACKEND_DIR"
    rm -rf "$FRONTEND_DIR"

    echo "Cleaning data directory..."
    rm -rf data/*
    touch data/.gitkeep

    echo "Cleaning workspace..."
    rm -rf workspace/*
    touch workspace/.gitkeep

    echo
    echo "========================================="
    echo " Workspace cleaned successfully."
    echo "========================================="
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