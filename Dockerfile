FROM python:3.12-slim

WORKDIR /app

# Install curl, Node.js, and npm so we can run the MCP inspector
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl nodejs npm \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY amazon_mcp/ amazon_mcp/
COPY scripts/verify_install.sh scripts/verify_install.sh

ENV PYTHONUNBUFFERED=1 \
    AMAZON_MCP_DRY_RUN=1

# Tell Vite (used by the inspector) to bind to 0.0.0.0 so Render can route traffic to it
ENV HOST=0.0.0.0

# Start the MCP inspector, and have it launch the python MCP server
CMD ["npx", "-y", "@modelcontextprotocol/inspector", "python", "-m", "amazon_mcp"]
