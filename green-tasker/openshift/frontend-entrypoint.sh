#!/bin/sh
# Entrypoint script for frontend container to inject API URL

# Get backend URL from environment variable or use default
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:5000}"

# Create config.js file with the API URL
cat > /usr/share/nginx/html/config.js <<EOF
// Auto-generated configuration
window.API_URL = "${BACKEND_URL}";
EOF

echo "Frontend configured with API URL: ${BACKEND_URL}"

# Start nginx
exec nginx -g "daemon off;"

