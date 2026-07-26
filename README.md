# Job-Application-Tracker-Orchestrator

The Job Application Tracker Orchestrator is the central repository for managing the complete Job Application Tracker application. It automatically clones the backend and frontend repositories and provides scripts for running the application either with Docker or natively on your machine.

This repository simplifies local development by eliminating the need to manually clone, configure, and start multiple repositories.

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
        Docker Compose / Native Execution
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

## Running Modes

The orchestrator supports two ways of running the application.

| Mode | Script | Description |
|------|--------|-------------|
| Docker | `orchestrator.sh` | Builds Docker images and runs the application using Docker Compose. |
| Local | `orchestrator-local.sh` | Runs the backend and frontend directly on your machine without Docker. Ideal for development and debugging. |

## Running with Docker

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

## Running Without Docker Using the Local Orchestrator

Instead of manually cloning the repositories and starting each service individually, you can use the local orchestrator to automate the entire process.

The local orchestrator automatically:

- Checks the required prerequisites.
- Creates the `workspace/` directory (if needed).
- Clones the backend and frontend repositories (if they do not already exist).
- Updates the repositories when requested.
- Starts the Spring Boot backend.
- Installs frontend dependencies (if required).
- Starts the Vite development server.

### Launch the application

Interactive mode (recommended for development):

```bash
./orchestrator-local.sh launch
```

The application will continue running until you press **Ctrl+C**, at which point both the backend and frontend are stopped automatically.

### Launch in detached mode

To start the application in the background and immediately return to the terminal:

```bash
./orchestrator-local.sh launch --detach
```

Once started, the application can be stopped with:

```bash
./orchestrator-local.sh stop
```

### Available Commands

| Command | Description |
|---------|-------------|
| `launch` | Clone repositories (if needed) and start the backend and frontend |
| `launch --detach` | Start the application in the background and return immediately |
| `update` | Pull the latest changes from both repositories |
| `stop` | Stop a detached local application |
| `help` | Display the help menu |

## Continuous Integration

This repository includes two GitHub Actions workflows:

| Workflow | Purpose |
|----------|---------|
| Docker Orchestrator CI | Validates the Docker-based orchestrator (`orchestrator.sh`) |
| Local Orchestrator CI | Validates the native/local orchestrator (`orchestrator-local.sh`) by launching the application, verifying the backend and frontend, and shutting down the running processes |
