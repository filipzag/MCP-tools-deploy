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
WORKDIR /app/proxy
# Copy from the 'proxy' build context
COPY --from=proxy . .
# Install requirements globally
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

# Setup Security Detections MCP
WORKDIR /app/security-detections
COPY . .
RUN npm ci && npm run build

# Configuration
ENV MCP_COMMAND="node /app/security-detections/dist/index.js"
ENV MCP_CWD="/app/security-detections"

# Run Proxy
WORKDIR /app/proxy
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]

