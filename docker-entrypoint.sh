#!/bin/bash
set -e

cd /home/frappe/frappe-bench

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    FRAPPE CHAT SETUP                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -L "/home/frappe/frappe-bench/apps/frappe_chat" ]; then
    echo "[1/4] Symlinking frappe_chat app..."
    ln -sf /frappe_chat_source /home/frappe/frappe-bench/apps/frappe_chat
else
    echo "[1/4] frappe_chat already linked"
fi

if ! python3 -c "import frappe_chat" 2>/dev/null; then
    echo "[2/4] Installing frappe_chat package..."
    pip3 install -q -e apps/frappe_chat --no-deps
else
    echo "[2/4] frappe_chat already installed"
fi

if [ ! -d "/home/frappe/frappe-bench/sites/chat.localhost" ]; then
    echo "[3/4] Creating site chat.localhost..."
    bench new-site chat.localhost \
        --mariadb-root-password frappe_root \
        --admin-password admin \
        --db-host frappe-mariadb \
        --no-mariadb-socket \
        --install-app frappe_chat
else
    echo "[3/4] Site already exists"
fi

if [ -f "/home/frappe/frappe-bench/sites/chat.localhost/site_config.json" ]; then
    echo "[4/4] Updating site config..."
    python3 << 'PYTHON'
import json
config_file = "/home/frappe/frappe-bench/sites/chat.localhost/site_config.json"
with open(config_file, 'r') as f:
    config = json.load(f)
config['db_host'] = 'frappe-mariadb'
with open(config_file, 'w') as f:
    json.dump(config, f, indent=1)
PYTHON
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                      READY TO USE                          ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  Backend URL    : http://localhost:8000                    ║"
echo "║                                                            ║"
echo "║  Admin Login                                               ║"
echo "║    Username     : Administrator                            ║"
echo "║    Password     : admin                                    ║"
echo "║                                                            ║"
echo "║  Test Users                                                ║"
echo "║    user1@turium.ai / Turium!2026                           ║"
echo "║    user2@turium.ai / Turium!2026                           ║"
echo "║                                                            ║"
echo "║  Database                                                  ║"
echo "║    Host         : frappe-mariadb                           ║"
echo "║    Root Pass    : frappe_root                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Starting Frappe server on port 8000..."
exec bench serve --port 8000 --noreload
