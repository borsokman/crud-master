#!/bin/bash

# Install Python, Pip, and Postgres dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv rabbitmq-server postgresql postgresql-contrib libpq-dev nodejs npm

# Install PM2 globally (to manage Python processes)
sudo npm install -g pm2

# Database setup using variables passed from Vagrant
sudo -u postgres psql <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\c $DB_NAME
GRANT ALL ON SCHEMA public TO $DB_USER;
EOF

# Setup application
cd /vagrant/srcs/billing-app
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt

# Start with PM2 using the python3 interpreter
pm2 start server.py --name "billing-api" --interpreter ./venv/bin/python3