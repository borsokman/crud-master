#!/usr/bin/env bash
set -euo pipefail

set -a
source .env
set +a

vagrant up --provision

# Ensure apps are running (idempotent) - run PM2 as vagrant user
vagrant ssh gateway-vm -c "cd /vagrant/srcs/api-gateway-app && pm2 restart gateway-api --update-env || pm2 start server.py --name gateway-api --interpreter ./venv/bin/python3 --update-env"
vagrant ssh inventory-vm -c "cd /vagrant/srcs/inventory-app && pm2 restart inventory-api --update-env || pm2 start server.py --name inventory-api --interpreter ./venv/bin/python3 --update-env"
vagrant ssh billing-vm -c "cd /vagrant/srcs/billing-app && pm2 restart billing-api --update-env || pm2 start server.py --name billing-api --interpreter ./venv/bin/python3 --update-env"

# Save PM2 process list so reboot restores processes
vagrant ssh gateway-vm -c "pm2 save"
vagrant ssh inventory-vm -c "pm2 save"
vagrant ssh billing-vm -c "pm2 save"

echo "All VMs up and apps running."