#!/usr/bin/env bash
set -euo pipefail

: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:?DB_PORT is required}"
: "${RABBITMQ_HOST:?RABBITMQ_HOST is required}"
: "${RABBITMQ_PORT:?RABBITMQ_PORT is required}"
: "${RABBITMQ_USER:?RABBITMQ_USER is required}"
: "${RABBITMQ_PASSWORD:?RABBITMQ_PASSWORD is required}"

APP_DIR="/vagrant/srcs/billing-app"
VENV_DIR="/home/vagrant/.venvs/billing-app"

sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv rabbitmq-server postgresql postgresql-contrib libpq-dev nodejs npm
sudo npm install -g pm2

if systemctl list-unit-files | grep -q '^postgresql\.service'; then
  sudo systemctl enable --now postgresql
elif systemctl list-unit-files | grep -q '^postgresql@.*\.service'; then
  PG_UNIT="$(systemctl list-unit-files | awk '/^postgresql@.*\.service/ {print $1; exit}')"
  sudo systemctl enable --now "${PG_UNIT}"
else
  sudo pg_ctlcluster 16 main start || sudo pg_ctlcluster 15 main start || true
fi
sudo systemctl enable --now rabbitmq-server

for i in {1..60}; do
  if sudo -u postgres pg_isready >/dev/null 2>&1; then break; fi
  echo "Waiting for PostgreSQL to be ready... ($i/60)"
  sleep 1
done
sudo -u postgres pg_isready >/dev/null 2>&1 || { echo "PostgreSQL not ready"; exit 1; }

sudo -u postgres psql \
  -v db_name="${DB_NAME}" \
  -v db_user="${DB_USER}" \
  -v db_password="${DB_PASSWORD}" \
  -f /vagrant/scripts/sql/init_billing.sql

sudo rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASSWORD}" 2>/dev/null || true
sudo rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*"

mkdir -p /home/vagrant/.venvs
rm -rf "${VENV_DIR}"
python3 -m venv "${VENV_DIR}"
"${VENV_DIR}/bin/python" -m ensurepip --upgrade
"${VENV_DIR}/bin/python" -m pip install --upgrade pip setuptools wheel
"${VENV_DIR}/bin/python" -m pip install -r "${APP_DIR}/requirements.txt"

cat >/tmp/billing-api.env <<EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
RABBITMQ_HOST=${RABBITMQ_HOST}
RABBITMQ_PORT=${RABBITMQ_PORT}
RABBITMQ_USER=${RABBITMQ_USER}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
EOF

set -a
source /tmp/billing-api.env
set +a

cd "${APP_DIR}"
pm2 describe billing-api >/dev/null 2>&1 \
  && pm2 restart billing-api --update-env \
  || pm2 start server.py --name billing-api --interpreter "${VENV_DIR}/bin/python" --update-env

pm2 save
sudo env PATH="$PATH" pm2 startup systemd -u vagrant --hp /home/vagrant || true
sudo systemctl enable pm2-vagrant || true
sudo systemctl restart pm2-vagrant || true