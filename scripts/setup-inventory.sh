#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs postgresql postgresql-contrib

# Create movies database and user
sudo -u postgres psql <<EOF
CREATE DATABASE movies;
CREATE USER movies_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE movies TO movies_user;
\c movies
GRANT ALL ON SCHEMA public TO movies_user;
EOF

# Navigate to app directory and install dependencies
cd /vagrant/srcs/inventory-app
npm install
