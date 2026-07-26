# Job-Application-Tracker-Orchestrator

The Job Application Tracker Orchestrator is the central repository for managing the complete Job Application Tracker application. It automatically clones the backend and frontend repositories, builds their Docker images, and starts the entire application stack with a single command.

This repository is intended to provide a simple developer experience for running the project locally without manually cloning or configuring multiple repositories.

## Project Repositories

The complete application is split across the following repositories:

* **Backend (Spring Boot API):** https://github.com/SAHIL-VARTAK/Job-Application-Tracker
* **Frontend (React + Vite):** https://github.com/SAHIL-VARTAK/Job-Application-Tracker-UI

The orchestrator automatically clones these repositories into the local `workspace/` directory when required.

## Running with the Orchestrator (Recommended)

The orchestrator provides a simplified interface for managing the complete application.

```bash
./orchestrator.sh launch
```

Additional commands:

```bash
./orchestrator.sh update
./orchestrator.sh stop
./orchestrator.sh logs
./orchestrator.sh health
./orchestrator.sh clean
```

The orchestrator automatically:

* Checks system prerequisites.
* Creates the required workspace structure.
* Clones the backend and frontend repositories (if they do not already exist).
* Builds the Docker images.
* Starts the complete application stack.

## Running with Docker Compose

If the backend and frontend repositories have already been cloned into the `workspace/` directory, you can also manage the application directly with Docker Compose.

Start the application:

```bash
docker compose up --build
```

Run in detached mode:

```bash
docker compose up -d
```

Stop the application:

```bash
docker compose down
```

View container logs:

```bash
docker compose logs
```
