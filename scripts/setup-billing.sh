#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs postgresql postgresql-contrib rabbitmq-server

# Create orders database and user
sudo -u postgres psql <<EOF
CREATE DATABASE orders;
CREATE USER orders_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE orders TO orders_user;
\c orders
GRANT ALL ON SCHEMA public TO orders_user;
EOF

# Navigate to app directory and install dependencies
cd /vagrant/srcs/billing-app
npm install
