# Job-Application-Tracker-Orchestrator

The Job Application Tracker Orchestrator is the central repository for managing the complete Job Application Tracker application. It automatically clones the backend and frontend repositories, builds their Docker images, and starts the entire application stack with a single command.

This repository is intended to provide a simple developer experience for running the project locally without manually cloning or configuring multiple repositories.

## Project Repositories

The complete application is split across the following repositories:

* **Backend (Spring Boot API):** https://github.com/SAHIL-VARTAK/Job-Application-Tracker
* **Frontend (React + Vite):** https://github.com/SAHIL-VARTAK/Job-Application-Tracker-UI

The orchestrator automatically clones these repositories into the local `workspace/` directory when required.

## Architecture

```
                 Orchestrator
                      │
      ┌───────────────┴───────────────┐
      │                               │
      ▼                               ▼
Backend (Spring Boot)         Frontend (React + Vite)
      │                               │
      └───────────────┬───────────────┘
                      │
                 Docker Compose
                      │
                      ▼
                Running Application
```

The orchestrator manages repository cloning and Docker lifecycle, while Docker Compose is responsible only for building and running the application containers.

## Prerequisites

Before running the project, ensure the following tools are installed:

- Git
- Docker
- Docker Compose

The orchestrator automatically verifies these prerequisites before launching the application.

## Running with the Orchestrator (Recommended)

The orchestrator provides a simplified interface for managing the complete application.

```bash
./orchestrator.sh launch
```

### Available Commands

| Command | Description |
|---------|-------------|
| `launch` | Clone repositories (if needed), build images, and start the application |
| `update` | Pull the latest changes from both repositories and restart the application |
| `stop` | Stop all running containers |
| `logs` | View logs from all services |
| `logs backend` | View backend logs only |
| `logs frontend` | View frontend logs only |
| `health` | Verify container and endpoint health |
| `clean` | Remove cloned repositories, Docker resources, and local database |
| `help` | Display the help menu |

The orchestrator automatically:

* Checks system prerequisites.
* Creates the required workspace structure.
* Clones the backend and frontend repositories (if they do not already exist).
* Builds the Docker images.
* Starts the complete application stack.

## Running with Docker Compose

If the backend and frontend repositories have already been cloned into the `workspace/` directory, you can also manage the application directly with Docker Compose.

Expected directory structure:

```
workspace/
├── Job-Application-Tracker/
└── Job-Application-Tracker-UI/
```

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

## Application URLs

Once the application is running:

| Service | URL |
|---------|-----|
| Frontend | http://localhost:5173 |
| Backend API | http://localhost:8080 |
| Swagger UI | http://localhost:8080/swagger-ui/index.html |

## Running Without Docker

For development, you can run the backend and frontend directly without Docker.

### 1. Clone the repositories

```bash
git clone https://github.com/SAHIL-VARTAK/Job-Application-Tracker.git workspace/Job-Application-Tracker
git clone https://github.com/SAHIL-VARTAK/Job-Application-Tracker-UI.git workspace/Job-Application-Tracker-UI
```

### 2. Start the backend

```bash
cd workspace/Job-Application-Tracker
./mvnw spring-boot:run
```

Or, if Maven is installed globally:

```bash
mvn spring-boot:run
```

The backend will start on:

```
http://localhost:8080
```

### 3. Start the frontend

Open another terminal.

```bash
cd workspace/Job-Application-Tracker-UI
npm install
npm run dev
```

The frontend will be available at:

```
http://localhost:5173
```

The Vite development server proxies API requests to the Spring Boot backend, so no additional frontend configuration is required.
