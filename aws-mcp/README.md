# AWS MCP Proxy Server

This is a Model Context Protocol (MCP) server that acts as a proxy to an AWS MCP service. It handles AWS IAM authentication (SigV4) and protocol translation, allowing local MCP clients to interact with AWS MCP agents.

## Prerequisites

- Python 3.10+
- AWS Credentials configured (typically in `~/.aws/credentials`)
- `mcp-proxy-for-aws` package and its dependencies

## Installation

1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd aws_mcp
   ```

2. Install dependencies:
   ```bash
   pip install fastapi uvicorn mcp-proxy-for-aws boto3
   ```

## Configuration

The server is configured in `server.py` with the following default settings:

- **AWS Region**: `us-east-1`
- **AWS Service**: `aws-mcp`
- **AWS Profile**: `private` (Ensure you have a profile named `private` in your AWS credentials, or update the code to use your preferred profile)
- **Upstream URL**: `https://aws-mcp.us-east-1.api.aws/mcp`

## Usage

Start the server:

```bash
python3 server.py
```

The server will start on `http://0.0.0.0:3001`.

## Testing

You can test the server using `curl` to send a JSON-RPC ping request:

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "ping", "id": 1}' \
  http://localhost:3001/proxy
```

Expected response:
```json
{"jsonrpc":"2.0","id":1,"result":{}}
```

To list available tools:
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 2}' \
  http://localhost:3001/proxy
```
