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
NC='\033[0m'

BACKEND_PID=""
FRONTEND_PID=""

PID_DIR=".orchestrator-local"

BACKEND_PID_FILE="$PID_DIR/backend.pid"
FRONTEND_PID_FILE="$PID_DIR/frontend.pid"

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
    echo -e "${BOLD}Job Application Tracker Local Orchestrator${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator-local.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}launch${NC}               Clone repositories and run locally"
    echo -e "  ${GREEN}launch --detach${NC}      Start locally and return immediately"
    echo -e "  ${GREEN}update${NC}               Update repositories"
    echo -e "  ${GREEN}stop${NC}                 Stop locally running application"
    echo -e "  ${GREEN}help${NC}                 Show this help message"
}

save_pids() {
    mkdir -p "$PID_DIR"

    echo "$BACKEND_PID" > "$BACKEND_PID_FILE"
    echo "$FRONTEND_PID" > "$FRONTEND_PID_FILE"
}

remove_pids() {
    rm -f "$BACKEND_PID_FILE" "$FRONTEND_PID_FILE"
}

stop_services() {
    print_info "Stopping local services..."

    if [[ -f "$BACKEND_PID_FILE" ]]; then
        kill "$(cat "$BACKEND_PID_FILE")" 2>/dev/null || true
    fi

    if [[ -f "$FRONTEND_PID_FILE" ]]; then
        kill "$(cat "$FRONTEND_PID_FILE")" 2>/dev/null || true
    fi

    wait 2>/dev/null || true

    remove_pids

    print_success "Services stopped."
}

cleanup() {
    echo

    stop_services

    exit 0
}

trap cleanup INT TERM

check_prerequisites() {
    command -v git >/dev/null 2>&1 || {
        print_error "Git is not installed."
        exit 1
    }

    command -v java >/dev/null 2>&1 || {
        print_error "Java is not installed."
        exit 1
    }

    command -v node >/dev/null 2>&1 || {
        print_error "Node.js is not installed."
        exit 1
    }

    command -v npm >/dev/null 2>&1 || {
        print_error "npm is not installed."
        exit 1
    }

    command -v curl >/dev/null 2>&1 || {
        print_error "curl is not installed."
        exit 1
    }

    if [[ ! -f "$BACKEND_DIR/mvnw" && ! -f "$BACKEND_DIR/mvnw.cmd" ]]; then
        command -v mvn >/dev/null 2>&1 || {
            print_error "Neither Maven Wrapper nor Maven is installed."
            exit 1
        }
    fi
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
    print_info "Updating repositories..."

    for repo_dir in "$BACKEND_DIR" "$FRONTEND_DIR"
    do
        if [[ ! -d "$repo_dir/.git" ]]; then
            print_error "Repository not found: $repo_dir"
            exit 1
        fi

        repo_name=$(basename "$repo_dir")

        print_info "Updating $repo_name..."

        (
            cd "$repo_dir"
            git fetch --all
            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            git pull origin "$CURRENT_BRANCH"
        )

        print_success "$repo_name updated."
    done
}

start_backend() {
    print_info "Starting backend..."

    cd "$BACKEND_DIR"

    if [[ -f "mvnw" ]]; then
        ./mvnw spring-boot:run &
    elif [[ -f "mvnw.cmd" ]]; then
        ./mvnw.cmd spring-boot:run &
    else
        mvn spring-boot:run &
    fi

    BACKEND_PID=$!

    cd - >/dev/null
}

wait_for_backend() {
    print_info "Waiting for backend..."

    until curl --silent http://localhost:8080 >/dev/null
    do
        sleep 2
    done

    print_success "Backend started."
}

start_frontend() {
    print_info "Starting frontend..."
    cd "$FRONTEND_DIR"

    if [[ ! -d node_modules ]]; then
        print_info "Installing frontend dependencies..."
        npm install
    fi

    npm run dev &
    FRONTEND_PID=$!

    cd - >/dev/null
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

    start_backend
    wait_for_backend
    start_frontend

    print_header "Job Application Tracker is running!"
    print_application_urls
    save_pids

    if [[ "${2:-}" == "--detach" || "${2:-}" == "-d" ]]; then
        print_success "Running in detached mode."
        print_info "Use './orchestrator-local.sh stop' to stop the application."
        exit 0
    fi

    print_info "Press Ctrl+C to stop."
    wait
}

update() {
    check_prerequisites

    update_repositories

    print_success "Repositories updated."
}

stop() {
    if [[ ! -d "$PID_DIR" ]]; then
        print_info "Application is not running."
        return
    fi

    stop_services
}

case "${1:-help}" in
    launch)
        launch "$@"
        ;;
    update)
        update
        ;;
    stop)
        stop
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