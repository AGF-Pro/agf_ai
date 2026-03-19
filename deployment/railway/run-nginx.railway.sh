#!/bin/sh
set -e

# =============================================================================
# Onyx nginx entrypoint for Railway
# =============================================================================
# Railway handles HTTPS at the edge. This script:
#   1. Resolves env-var defaults
#   2. Substitutes variables in the nginx templates
#   3. Handles optional MCP server config
#   4. Polls the api_server /health endpoint until it responds 200
#   5. Starts nginx (reloads config every 6 h to pick up cert rotations)
# =============================================================================

export ONYX_BACKEND_API_HOST="${ONYX_BACKEND_API_HOST:-api_server}"
export ONYX_WEB_SERVER_HOST="${ONYX_WEB_SERVER_HOST:-web_server}"
export ONYX_MCP_SERVER_HOST="${ONYX_MCP_SERVER_HOST:-mcp_server}"

# Railway injects PORT; fall back to 80
export NGINX_PORT="${PORT:-80}"

export NGINX_PROXY_CONNECT_TIMEOUT="${NGINX_PROXY_CONNECT_TIMEOUT:-300}"
export NGINX_PROXY_SEND_TIMEOUT="${NGINX_PROXY_SEND_TIMEOUT:-300}"
export NGINX_PROXY_READ_TIMEOUT="${NGINX_PROXY_READ_TIMEOUT:-300}"

echo "==> nginx: API server      : $ONYX_BACKEND_API_HOST"
echo "==> nginx: Web server      : $ONYX_WEB_SERVER_HOST"
echo "==> nginx: Listening port  : $NGINX_PORT"
echo "==> nginx: Proxy timeouts  : connect=${NGINX_PROXY_CONNECT_TIMEOUT}s send=${NGINX_PROXY_SEND_TIMEOUT}s read=${NGINX_PROXY_READ_TIMEOUT}s"

# Substitute all known variables into the main nginx config
envsubst '$NGINX_PORT $ONYX_BACKEND_API_HOST $ONYX_WEB_SERVER_HOST $ONYX_MCP_SERVER_HOST $NGINX_PROXY_CONNECT_TIMEOUT $NGINX_PROXY_SEND_TIMEOUT $NGINX_PROXY_READ_TIMEOUT' \
  < /etc/nginx/conf.d/nginx.conf.template.railway \
  > /etc/nginx/conf.d/app.conf

# MCP server: generate or stub the include files
if [ "${MCP_SERVER_ENABLED}" = "True" ] || [ "${MCP_SERVER_ENABLED}" = "true" ]; then
  echo "==> nginx: MCP server enabled"
  envsubst '$ONYX_MCP_SERVER_HOST' \
    < /etc/nginx/conf.d/mcp_upstream.conf.inc.template \
    > /etc/nginx/conf.d/mcp_upstream.conf.inc
  envsubst '$ONYX_MCP_SERVER_HOST' \
    < /etc/nginx/conf.d/mcp.conf.inc.template \
    > /etc/nginx/conf.d/mcp.conf.inc
else
  echo "==> nginx: MCP server disabled – writing empty include stubs"
  echo "# MCP disabled" > /etc/nginx/conf.d/mcp_upstream.conf.inc
  echo "# MCP disabled" > /etc/nginx/conf.d/mcp.conf.inc
fi

# Wait for api_server to be healthy before starting nginx
echo "==> nginx: Waiting for API server to become healthy..."
until [ "$(curl -s -o /dev/null -w '%{http_code}' "http://${ONYX_BACKEND_API_HOST}:8080/health")" = "200" ]; do
  echo "==> nginx: api_server not ready yet – retrying in 5 s..."
  sleep 5
done
echo "==> nginx: API server is healthy. Starting nginx on port ${NGINX_PORT}."

# Reload config every 6 h (good practice even without Let's Encrypt)
while :; do sleep 6h & wait; nginx -s reload; done &

exec nginx -g "daemon off;"
