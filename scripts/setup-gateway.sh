#!/bin/bash

# Install Python, Pip, and Postgres dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv nodejs npm

# Install PM2 globally (to manage Python processes)
sudo npm install -g pm2

# Setup application
cd /vagrant/srcs/api-gateway-app
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt

# Start with PM2 using the python3 interpreter
pm2 restart gateway-api --update-env || pm2 start server.py --name "gateway-api" --interpreter ./venv/bin/python3