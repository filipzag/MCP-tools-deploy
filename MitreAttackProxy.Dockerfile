FROM python:3.11-slim

# Install Node.js and build tools
# better-sqlite3 requires build-essential
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    python3-dev \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Setup Proxy
# We assume the proxy source code is copied into ./proxy in the build context
# by the docker-compose build process (via additional_contexts if supported, or require manual copy)
# Given the user constraints, we rely on additional_contexts working.
WORKDIR /app/proxy
COPY --from=proxy . .
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

# Setup Mitre Attack MCP
WORKDIR /app/mitre-attack
COPY . .
RUN npm ci && npm run build

# Configuration
ENV MCP_COMMAND="node /app/mitre-attack/dist/index.js"
ENV MCP_CWD="/app/mitre-attack"

# Run Proxy
WORKDIR /app/proxy
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]

