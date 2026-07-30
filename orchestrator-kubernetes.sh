#!/usr/bin/env bash
set -e

BACKEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker.git"
FRONTEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker-UI.git"

WORKSPACE_DIR="workspace"

BACKEND_NAME="Job-Application-Tracker"
FRONTEND_NAME="Job-Application-Tracker-UI"

BACKEND_DIR="$WORKSPACE_DIR/$BACKEND_NAME"
FRONTEND_DIR="$WORKSPACE_DIR/$FRONTEND_NAME"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

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
    echo -e "${BLUE}Frontend :${NC} ${GREEN}http://localhost${NC}"
    echo -e "${BLUE}Backend  :${NC} ${GREEN}http://localhost/api${NC}"
    echo -e "${BLUE}Swagger  :${NC} ${GREEN}http://localhost/swagger-ui/index.html${NC}"
}

show_help() {
    echo
    echo -e "${BOLD}Job Application Tracker Kubernetes Orchestrator${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator-kubernetes.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}launch${NC}                  Clone repositories and deploy application"
    echo -e "  ${GREEN}update${NC}                  Update repositories and redeploy"
    echo -e "  ${GREEN}stop${NC}                    Remove application resources"
    echo -e "  ${GREEN}logs [backend|frontend|ingress|all]${NC}"
    echo -e "  ${GREEN}health${NC}                  Show cluster status"
    echo -e "  ${GREEN}clean${NC}                   Destroy cluster and remove workspace"
    echo -e "  ${GREEN}help${NC}                    Show this help"
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

    command -v kubectl >/dev/null 2>&1 || {
        print_error "kubectl is not installed."
        exit 1
    }

    command -v kind >/dev/null 2>&1 || {
        print_error "kind is not installed."
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
    print_info "Updating repositories..."

    for repo_dir in "$BACKEND_DIR" "$FRONTEND_DIR"
    do
        if [[ ! -d "$repo_dir/.git" ]]; then
            print_error "$repo_dir not found."
            exit 1
        fi
        (
            cd "$repo_dir"
            git fetch --all
            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            git pull origin "$CURRENT_BRANCH"
        )

        print_success "$(basename "$repo_dir") updated."
    done
}

cluster_exists() {
    kind get clusters | grep -qx "job-tracker"
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

    if ! cluster_exists; then
        print_info "Creating Kind cluster..."
        ./kubernetes/build-cluster.sh
    else
        print_success "Kind cluster already exists."
    fi

    print_info "Building Docker images..."
    ./kubernetes/build.sh

    print_info "Deploying application..."
    ./kubernetes/deploy.sh

    print_header "Job Application Tracker is running!"
    print_application_urls
}

update() {
    check_prerequisites

    update_repositories

    print_info "Rebuilding images..."
    ./kubernetes/build.sh

    print_info "Restarting deployments..."
    kubectl rollout restart deployment/backend -n job-tracker
    kubectl rollout restart deployment/frontend -n job-tracker
    kubectl rollout status deployment/backend -n job-tracker
    kubectl rollout status deployment/frontend -n job-tracker

    print_header "Application updated."
    print_application_urls
}

stop() {
    check_prerequisites

    print_info "Stopping Job Tracker..."

    ./kubernetes/stop.sh

    print_header "Application stopped."
}

logs() {
    check_prerequisites

    case "${2:-all}" in
        backend)
            kubectl logs -f deployment/backend -n job-tracker
            ;;
        frontend)
            kubectl logs -f deployment/frontend -n job-tracker
            ;;
        ingress)
            kubectl logs -f deployment/ingress-nginx-controller \
                -n ingress-nginx
            ;;
        all)
            kubectl get pods -n job-tracker
            ;;
        *)
            print_error "Invalid option."
            exit 1
            ;;
    esac
}

health() {
    check_prerequisites
    ./kubernetes/status.sh
}

clean() {
    check_prerequisites

    print_header "Clean Workspace"
    echo "This will remove:"
    echo "  • Kind cluster"
    echo "  • Kubernetes resources"
    echo "  • Cloned repositories"
    echo
    read -rp "Continue? (Y/N): " response

    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            ;;
        *)
            print_info "Cancelled."
            return
            ;;

    esac
    
    if cluster_exists; then
        ./kubernetes/delete.sh
        ./kubernetes/destroy-cluster.sh
    fi

    print_info "Removing workspace..."
    rm -rf "$BACKEND_DIR"
    rm -rf "$FRONTEND_DIR"
    rm -rf workspace/*

    touch workspace/.gitkeep

    print_header "Workspace cleaned successfully."
}

case "${1:-help}" in
    launch)
        launch
        ;;
    update)
        update
        ;;
    stop)
        stop
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
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
