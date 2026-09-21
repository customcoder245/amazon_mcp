#!/bin/bash
set -e

PUBLIC_PORT="${PORT:-8080}"
MCP_PORT=8780
INSPECTOR_UI_PORT=5173
INSPECTOR_PROXY_PORT=3000

# ── 1. Start Python MCP server (internal) ────────────────────────────────────
echo "==> [1/4] Starting Amazon MCP server on 127.0.0.1:${MCP_PORT}..."
AMAZON_MCP_TRANSPORT=streamable-http \
AMAZON_MCP_HOST=127.0.0.1 \
AMAZON_MCP_PORT=${MCP_PORT} \
python -m amazon_mcp &

sleep 3

# ── 2. Start MCP Inspector (UI + proxy, both internal) ────────────────────────
echo "==> [2/4] Starting MCP Inspector (UI:${INSPECTOR_UI_PORT}, proxy:${INSPECTOR_PROXY_PORT})..."
CLIENT_PORT=${INSPECTOR_UI_PORT} \
SERVER_PORT=${INSPECTOR_PROXY_PORT} \
ALLOWED_ORIGINS="${ALLOWED_ORIGINS:-*}" \
npx -y @modelcontextprotocol/inspector &

sleep 6

# ── 3. Write nginx config ─────────────────────────────────────────────────────
echo "==> [3/4] Writing nginx config (public port: ${PUBLIC_PORT})..."
cat > /etc/nginx/nginx.conf << NGINX_CONF
user root;
worker_processes 1;
error_log /dev/stderr warn;
pid /tmp/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include      /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log   /dev/stdout;

    server {
        listen      ${PUBLIC_PORT};
        server_name _;

        # ── MCP API → Python MCP server ──────────────────────────────────────
        location /mcp {
            proxy_pass         http://127.0.0.1:${MCP_PORT}/mcp;
            proxy_http_version 1.1;
            proxy_set_header   Host \$host;
            proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Proto \$scheme;
            proxy_buffering    off;
            proxy_read_timeout 300s;
            proxy_send_timeout 300s;
        }

        # ── Health check → Python MCP server ─────────────────────────────────
        location /health {
            proxy_pass http://127.0.0.1:${MCP_PORT}/health;
        }

        # ── Block OAuth discovery — server uses Bearer auth, not OAuth ─────────
        # Without this, a 401 from /mcp triggers OAuth discovery which returns
        # the Inspector HTML (200) instead of a proper 404, confusing the client.
        location /.well-known/ {
            return 404 '{"ok":false,"error":"OAuth not supported. Use Bearer token."}';
            add_header Content-Type application/json;
        }

        # ── Inspector UI (Vite proxies /api/* to Inspector proxy internally) ──
        location / {
            proxy_pass         http://127.0.0.1:${INSPECTOR_UI_PORT};
            proxy_http_version 1.1;
            proxy_set_header   Upgrade    \$http_upgrade;
            proxy_set_header   Connection "upgrade";
            proxy_set_header   Host       \$host;
            proxy_buffering    off;
            proxy_read_timeout 120s;
        }
    }
}
NGINX_CONF

# ── 4. Start nginx in foreground (Render keeps the container alive via this) ──
echo "==> [4/4] Starting nginx on port ${PUBLIC_PORT}..."
exec nginx -g 'daemon off;'
