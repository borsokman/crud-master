#!/usr/bin/env bash
set -euo pipefail

set -a
source .env
set +a

vagrant up --provision

# Ensure apps are running (idempotent)
vagrant ssh gateway-vm -c "cd /vagrant/srcs/api-gateway-app && sudo pm2 restart gateway-api --update-env || sudo pm2 start server.py --name gateway-api --interpreter ./venv/bin/python3"
vagrant ssh inventory-vm -c "cd /vagrant/srcs/inventory-app && sudo pm2 restart inventory-api --update-env || sudo pm2 start server.py --name inventory-api --interpreter ./venv/bin/python3"
vagrant ssh billing-vm -c "cd /vagrant/srcs/billing-app && sudo pm2 restart billing-api --update-env || sudo pm2 start server.py --name billing-api --interpreter ./venv/bin/python3"

# Save PM2 process list so reboot restores processes
vagrant ssh gateway-vm -c "sudo pm2 save"
vagrant ssh inventory-vm -c "sudo pm2 save"
vagrant ssh billing-vm -c "sudo pm2 save"

echo "All VMs up and apps running."