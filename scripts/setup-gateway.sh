#!/usr/bin/env bash
set -euo pipefail

# Install Python, Pip, and Postgres dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv nodejs npm

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

# Setup application
cd /vagrant/srcs/api-gateway-app
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

# Start with PM2 using the python3 interpreter
pm2 restart gateway-api --update-env || pm2 start server.py --name "gateway-api" --interpreter ./venv/bin/python3

# Persist PM2 process list
pm2 save
pm2 startup systemd -u vagrant --hp /home/vagrant | sed 's/^sudo //g' | bash || true