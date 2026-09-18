#!/bin/bash

# Render injects $PORT; fall back to 8780 for local dev
export AMAZON_MCP_TRANSPORT=streamable-http
export AMAZON_MCP_HOST=0.0.0.0
export AMAZON_MCP_PORT="${PORT:-8780}"

# Start the MCP server in the foreground so Render keeps the process alive
exec python -m amazon_mcp
