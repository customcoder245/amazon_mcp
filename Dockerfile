FROM python:3.12-slim

WORKDIR /app

# Install curl for health checks
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY amazon_mcp/ amazon_mcp/
COPY scripts/verify_install.sh scripts/verify_install.sh

ENV PYTHONUNBUFFERED=1 \
    AMAZON_MCP_DRY_RUN=1 \
    AMAZON_MCP_TRANSPORT=streamable-http \
    AMAZON_MCP_HOST=0.0.0.0

COPY start.sh .
RUN chmod +x start.sh

# Render dynamically assigns $PORT; start.sh reads it at runtime
CMD ["./start.sh"]
