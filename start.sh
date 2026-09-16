#!/bin/bash

# Start the Python MCP Server in HTTP mode in the background
export AMAZON_MCP_TRANSPORT=streamable-http
export AMAZON_MCP_HOST=127.0.0.1
export AMAZON_MCP_PORT=8780
python -m amazon_mcp &

# Give it a second to start
sleep 2

# Allow the Render URL to access the inspector to prevent DNS rebinding errors
export ALLOWED_ORIGINS="${RENDER_EXTERNAL_URL}"

# Start the MCP Inspector in the foreground (without ad-hoc command)
# This removes the "read-only" banner and lets you add servers manually.
npx -y @modelcontextprotocol/inspector
