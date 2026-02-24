FROM python:3.10-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir fastapi uvicorn mcp mcp-proxy-for-aws

# Copy server code
COPY server.py .

# Run the server
CMD ["python", "server.py"]
