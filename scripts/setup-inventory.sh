#!/usr/bin/env bash
set -euo pipefail

# --- Validate required env vars from Vagrant ---
: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:?DB_PORT is required}"

# Install Python, Pip, and Postgres dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv postgresql postgresql-contrib libpq-dev nodejs npm

# Install PM2 globally (to manage Python processes)
sudo npm install -g pm2

# --- Ensure PostgreSQL is running ---
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Wait for postgres readiness
until sudo -u postgres pg_isready >/dev/null 2>&1; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 1
done

# Database setup using variables passed from Vagrant
sudo -u postgres psql \
  -v db_name="${DB_NAME}" \
  -v db_user="${DB_USER}" \
  -v db_password="${DB_PASSWORD}" \
  -v db_host="${DB_HOST}" \
  -v db_port="${DB_PORT}" \
  -f /vagrant/scripts/sql/init_inventory.sql

# Setup application
cd /vagrant/srcs/inventory-app
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

# Export runtime env for app (used by Flask app / SQLAlchemy)
cat >/tmp/inventory-api.env <<EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
EOF

# Start with PM2 using the python3 interpreter
pm2 describe inventory-api >/dev/null 2>&1 && pm2 restart inventory-api --update-env \
  || pm2 start server.py --name inventory-api --interpreter ./venv/bin/python3 --update-env
  
# Inject env then restart to ensure PM2 process gets env vars
pm2 restart inventory-api --update-env --env production || true

# Persist and enable PM2 on boot for vagrant user
pm2 save
pm2 startup systemd -u vagrant --hp /home/vagrant | sed 's/^sudo //g' | bash || true
