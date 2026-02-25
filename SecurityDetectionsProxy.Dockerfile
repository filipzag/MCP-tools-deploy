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

# Setup Detections Data
WORKDIR /detections
RUN apt-get update && apt-get install -y git && \
    # Download Sigma rules
    git clone --depth 1 --filter=blob:none --sparse https://github.com/SigmaHQ/sigma.git && \
    cd sigma && git sparse-checkout set rules rules-threat-hunting && cd .. && \
    # Download Splunk ESCU detections
    git clone --depth 1 --filter=blob:none --sparse https://github.com/splunk/security_content.git && \
    cd security_content && git sparse-checkout set detections stories && cd .. && \
    # Download Elastic detection rules
    git clone --depth 1 --filter=blob:none --sparse https://github.com/elastic/detection-rules.git && \
    cd detection-rules && git sparse-checkout set rules && cd .. && \
    # Download KQL hunting queries
    git clone --depth 1 https://github.com/Bert-JanP/Hunting-Queries-Detection-Rules.git kql-bertjanp && \
    git clone --depth 1 https://github.com/jkerai1/KQL-Queries.git kql-jkerai1

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
ENV SIGMA_PATHS="/detections/sigma/rules,/detections/sigma/rules-threat-hunting"
ENV SPLUNK_PATHS="/detections/security_content/detections"
ENV STORY_PATHS="/detections/security_content/stories"
ENV ELASTIC_PATHS="/detections/detection-rules/rules"
ENV KQL_PATHS="/detections/kql-bertjanp,/detections/kql-jkerai1"

# Run Proxy
WORKDIR /app/proxy
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]

