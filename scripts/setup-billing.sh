#!/bin/bash
set -euo pipefail

# --- Validate required env vars from Vagrant ---
: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:?DB_PORT is required}"
: "${RABBITMQ_HOST:?RABBITMQ_HOST is required}"
: "${RABBITMQ_PORT:?RABBITMQ_PORT is required}"
: "${RABBITMQ_USER:?RABBITMQ_USER is required}"
: "${RABBITMQ_PASSWORD:?RABBITMQ_PASSWORD is required}"

# Install dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv rabbitmq-server postgresql postgresql-contrib libpq-dev nodejs npm

# Install PM2 globally
sudo npm install -g pm2

# Ensure PostgreSQL/RabbitMQ is running
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

# Wait for postgres readiness
until sudo -u postgres pg_isready >/dev/null 2>&1; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 1
done

# Database setup
sudo -u postgres psql \
  -v db_name="${DB_NAME}" \
  -v db_user="${DB_USER}" \
  -v db_password="${DB_PASSWORD}" \
  -f /vagrant/scripts/sql/init_billing.sql

# RabbitMQ user init (idempotent)
sudo rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASSWORD}" 2>/dev/null || true
sudo rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*"

# App setup
cd /vagrant/srcs/billing-app
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

# Export runtime env for app
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

# Start/restart billing consumer
pm2 describe billing-api >/dev/null 2>&1 \
  && pm2 restart billing-api --update-env \
  || pm2 start server.py --name billing-api --interpreter ./venv/bin/python3 --update-env

# Persist and enable PM2 on boot for vagrant user
pm2 save
pm2 startup systemd -u vagrant --hp /home/vagrant | sed 's/^sudo //g' | bash || true