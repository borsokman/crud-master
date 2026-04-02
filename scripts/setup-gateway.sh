#!/usr/bin/env bash
set -euo pipefail

INVENTORY_URL="${INVENTORY_URL:-http://192.168.56.20:8080}"
RABBITMQ_HOST="${RABBITMQ_HOST:-192.168.56.30}"
RABBITMQ_PORT="${RABBITMQ_PORT:-5672}"
RABBITMQ_USER="${RABBITMQ_USER:-billing_user}"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-billing_pass}"

APP_DIR="/vagrant/srcs/api-gateway-app"
VENV_DIR="/home/vagrant/.venvs/gateway-app"

sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv nodejs npm
sudo npm install -g pm2

mkdir -p /home/vagrant/.venvs
rm -rf "${VENV_DIR}"
python3 -m venv "${VENV_DIR}"
"${VENV_DIR}/bin/python" -m ensurepip --upgrade
"${VENV_DIR}/bin/python" -m pip install --upgrade pip setuptools wheel
"${VENV_DIR}/bin/python" -m pip install -r "${APP_DIR}/requirements.txt"

cat >/tmp/gateway-api.env <<EOF
INVENTORY_URL=${INVENTORY_URL}
RABBITMQ_HOST=${RABBITMQ_HOST}
RABBITMQ_PORT=${RABBITMQ_PORT}
RABBITMQ_USER=${RABBITMQ_USER}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
EOF

set -a
source /tmp/gateway-api.env
set +a

cd "${APP_DIR}"
pm2 describe gateway-api >/dev/null 2>&1 \
  && pm2 restart gateway-api --update-env \
  || pm2 start server.py --name gateway-api --interpreter "${VENV_DIR}/bin/python" --update-env

pm2 save
sudo env PATH="$PATH" pm2 startup systemd -u vagrant --hp /home/vagrant || true
sudo systemctl enable pm2-vagrant || true
sudo systemctl restart pm2-vagrant || true