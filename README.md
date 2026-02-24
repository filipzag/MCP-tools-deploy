# Unified MCP Docker Deployment

This repository provides a unified Docker Compose setup to run multiple Model Context Protocol (MCP) servers tailored for security and threat detection workflows. 

The individual MCP components are linked as Git submodules for easy synchronization.

## Included Services

| Service | Port | Description |
|---------|------|-------------|
| **Elastic Security** | `8000` | Interfaces with Elastic Security/Kibana for rules, alerts, and detection templates. |
| **Security Detections** | `8001` | Generic security detections capability over MCP (proxied). |
| **MITRE ATT&CK** | `8004` | Queries the MITRE ATT&CK knowledge base (proxied). |
| **Atomic Red Team** | `8005` | Interfaces with Red Canary's Atomic Red Team test library (native FastMCP). |

## Quick Start Guide

Follow these straightforward steps to get all the tools running locally or on a server.

### 1. Clone the Repository (with Submodules)

Since the individual MCP components are tracked as Git submodules, you need to pull them down when you clone the repo:

```bash
# Clone the repository and initialize all submodules automatically
git clone --recursive <repository-url>
cd unified-docker

# If you already cloned normally, run this to pull exactly the submodule contents:
# git submodule update --init --recursive
```

### 2. Configure Environment Variables

All services are secured with Bearer token authentication to prevent unauthorized access. You must define these tokens (and Elastic credentials) in a `.env` file.

Copy the provided example configuration:

```bash
cp .env.example .env
```

Edit the `.env` file and set secure values for your authentication tokens. 
Example snippet from `.env`:
```text
SECURITY_DETECTIONS_AUTH_TOKEN=your-random-secure-string-1
MITRE_ATTACK_AUTH_TOKEN=your-random-secure-string-2
ATOMIC_RED_TEAM_AUTH_TOKEN=your-random-secure-string-3
```
*Note: You must also configure `docker-compose.yaml` with your `KIBANA_URL` and `ELASTIC_API_KEY` to use the Elastic Security MCP.*

### 3. Build and Run the Containers

Use Docker Compose to build the proxy containers and start the services in the background:

```bash
docker compose up -d --build
```

### 4. Verify Services are Running

You can check the health of any service using its port. For example, to check the MITRE ATT&CK service:

```bash
curl http://localhost:8004/health
```
*(Should return `{"status":"healthy"...}`)*

### 5. Connect your MCP Client

To connect an AI agent or Kibana to the servers, configure the MCP client with the corresponding HTTP endpoints and Bearer tokens. 

For example, to connect to the Atomic Red Team MCP, use:
- **URL**: `http://localhost:8005/mcp`
- **Auth Header (`Authorization`)**: `Bearer <YOUR_ATOMIC_RED_TEAM_TOKEN>`
- **Accept**: `application/json, text/event-stream`

## Troubleshooting

- **504 Gateway Timeout**: The initial requests to the `mitre-attack` or `atomic-red-team` servers may take longer (up to 2 minutes) if they are downloading their respective datasets on the first run. The proxy handles this correctly.
- **Port Conflicts**: If the services fail to start due to `address already in use`, check which ports are occupied using `sudo lsof -i :8000` and modify the exposed ports in `docker-compose.yaml`.
- **Missing Code**: If the sub-folders are empty, you forgot to pull the submodules. Run `git submodule update --init --recursive`.
