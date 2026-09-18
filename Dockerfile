FROM python:3.12-slim

WORKDIR /app

# Install curl, nginx (reverse proxy), Node.js + npm (MCP Inspector)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl nginx nodejs npm \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-cache MCP Inspector + default stdio server packages so built-in servers work
RUN npm install -g \
    @modelcontextprotocol/inspector \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-everything

COPY amazon_mcp/ amazon_mcp/
COPY scripts/verify_install.sh scripts/verify_install.sh

ENV PYTHONUNBUFFERED=1 \
    AMAZON_MCP_DRY_RUN=1

COPY start.sh .
RUN chmod +x start.sh

# Render injects $PORT at runtime; nginx binds to it via start.sh
CMD ["./start.sh"]
