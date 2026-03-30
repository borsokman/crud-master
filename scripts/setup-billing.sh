#!/bin/bash
set -euo pipefail

# Install dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv rabbitmq-server postgresql postgresql-contrib libpq-dev nodejs npm

# Install PM2 globally
sudo npm install -g pm2

# Ensure RabbitMQ user exists (idempotent)
sudo rabbitmqctl add_user billing_user billing_pass || true
sudo rabbitmqctl set_permissions -p / billing_user ".*" ".*" ".*"

# Database setup
sudo -u postgres psql -f /vagrant/scripts/sql/init_billing.sql

# App setup
cd /vagrant/srcs/billing-app
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt

# Start/restart billing consumer
pm2 restart billing-api --update-env || pm2 start server.py --name "billing-api" --interpreter ./venv/bin/python3

# Persist PM2 process list
pm2 save