#!/usr/bin/env bash

set -e

BACKEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker.git"
FRONTEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker-UI.git"

WORKSPACE_DIR="workspace"

BACKEND_NAME="Job-Application-Tracker"
FRONTEND_NAME="Job-Application-Tracker-UI"

BACKEND_DIR="$WORKSPACE_DIR/$BACKEND_NAME"
FRONTEND_DIR="$WORKSPACE_DIR/$FRONTEND_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    echo
    echo -e "${BOLD}=========================================${NC}"
    echo -e "${BOLD} $1${NC}"
    echo -e "${BOLD}=========================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_application_urls() {
    echo
    echo -e "${BLUE}Frontend :${NC} ${GREEN}http://localhost:5173${NC}"
    echo -e "${BLUE}Backend  :${NC} ${GREEN}http://localhost:8080${NC}"
    echo -e "${BLUE}Swagger  :${NC} ${GREEN}http://localhost:8080/swagger-ui/index.html${NC}"
}

show_help() {
    echo
    echo -e "${BOLD}Job Application Tracker Orchestrator${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}launch${NC}                  Clone repositories and start the application"
    echo -e "  ${GREEN}update${NC}                  Update repositories and restart the application"
    echo -e "  ${GREEN}stop${NC}                    Stop the application"
    echo -e "  ${GREEN}logs [backend|frontend]${NC} View application logs"
    echo -e "  ${GREEN}health${NC}                  Check application health"
    echo -e "  ${GREEN}clean${NC}                   Remove cloned repositories and Docker resources"
    echo -e "  ${GREEN}help${NC}                    Show this help message"
}

check_prerequisites() {
    command -v git >/dev/null 2>&1 || {
        print_error "Git is not installed."
        exit 1
    }

    command -v docker >/dev/null 2>&1 || {
        print_error "Docker is not installed."
        exit 1
    }

    docker info >/dev/null 2>&1 || {
        print_error "Docker is not running."
        exit 1
    }

    docker compose version >/dev/null 2>&1 || {
        print_error "Docker Compose is not available."
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
        print_success "$repo_name already exists."
        return
    fi

    print_info "Cloning $repo_name..."
    git clone "$repo_url" "$target_dir"
    print_success "$repo_name cloned successfully."
}

update_repositories() {
    echo
    print_info "Updating repositories..."

    for repo_dir in "$BACKEND_DIR" "$FRONTEND_DIR"; do
        if [[ ! -d "$repo_dir/.git" ]]; then
            print_error "Repository not found: $repo_dir"
            echo "Run './orchestrator.sh launch' first."
            exit 1
        fi

        repo_name=$(basename "$repo_dir")

        echo
        print_info "Updating $repo_name..."

        (
            cd "$repo_dir" || exit 1

            git fetch --all

            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

            git pull origin "$CURRENT_BRANCH"
        )

        print_success "$repo_name updated."
    done
}

start_application() {
    echo
    print_info "Building Docker images..."

    docker compose build

    echo
    print_info "Starting containers..."

    docker compose up -d
}

restart_application() {
    echo
    print_info "Stopping containers..."

    docker compose down

    echo
    print_info "Rebuilding images..."

    docker compose build

    echo
    print_info "Starting containers..."

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

    print_header "Job Application Tracker is running!"

    print_application_urls
}

stop() {
    check_prerequisites

    echo
    print_info "Stopping Job Application Tracker..."

    docker compose down

    print_header "Job Application Tracker stopped."
}

update() {
    check_prerequisites

    update_repositories

    restart_application

    print_header "Job Application Tracker updated!"

    print_application_urls
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

    print_header "Application Health"

    print_info "Docker"

    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        overall_status=1
    fi

    echo
    print_info "Containers"

    if docker compose ps --status running | grep -q "backend"; then
        print_success "Backend container is running"
    else
        print_error "Backend container is not running"
        overall_status=1
    fi

    if docker compose ps --status running | grep -q "frontend"; then
        print_success "Frontend container is running"
    else
        print_error "Frontend container is not running"
        overall_status=1
    fi

    echo
    print_info "Endpoints"

    if curl --silent --fail http://localhost:8080/api/applications >/dev/null; then
        print_success "Backend API  : http://localhost:8080/api/applications"
    else
        print_error "Backend API  : Unreachable"
        overall_status=1
    fi

    if curl --silent --fail http://localhost:8080/swagger-ui/index.html >/dev/null; then
        print_success "Swagger UI  : http://localhost:8080/swagger-ui/index.html"
    else
        print_error "Swagger UI  : Unreachable"
        overall_status=1
    fi

    if curl --silent --fail http://localhost:5173 >/dev/null; then
        print_success "Frontend    : http://localhost:5173"
    else
        print_error "Frontend    : Unreachable"
        overall_status=1
    fi

    echo
    print_info "Overall Status"

    if [[ $overall_status -eq 0 ]]; then
        print_success "Application is healthy"
        return 0
    else
        print_error "Application is unhealthy"
        return 1
    fi
}

clean() {
    check_prerequisites

    print_header "Clean Workspace"

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
            print_info "Clean operation cancelled."
            return
            ;;
    esac

    echo
    print_info "Stopping containers..."
    docker compose down --rmi local

    print_info "Removing cloned repositories..."
    rm -rf "$BACKEND_DIR"
    rm -rf "$FRONTEND_DIR"

    print_info "Cleaning data directory..."
    rm -rf data/*
    touch data/.gitkeep

    print_info "Cleaning workspace..."
    rm -rf workspace/*
    touch workspace/.gitkeep

    print_header "Workspace cleaned successfully."
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
        logs "$@"
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