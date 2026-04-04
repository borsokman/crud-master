#!/usr/bin/env bash
set -euo pipefail

# 1. Update system and install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv nodejs npm
sudo npm install -g pm2

# 2. Setup Python Virtual Environment (As the vagrant user)
echo "Setting up Python environment..."
APP_DIR="/vagrant/srcs/api-gateway-app"
VENV_DIR="/home/vagrant/.venvs/api-gateway-app"

# Create directories and change ownership to vagrant BEFORE creating the venv
mkdir -p /home/vagrant/.venvs
chown -R vagrant:vagrant /home/vagrant/.venvs

# Run venv creation and pip install as the vagrant user
sudo -u vagrant bash -c "
  python3 -m venv ${VENV_DIR}
  ${VENV_DIR}/bin/pip install --upgrade pip
  ${VENV_DIR}/bin/pip install -r ${APP_DIR}/requirements.txt
"

# 3. Start the Application with PM2 (As the vagrant user)
echo "Starting Gateway API with PM2..."
# We pass the environment variables directly to the PM2 start command
sudo -u vagrant bash -c "
  cd ${APP_DIR}
  
  # Export variables for this session so PM2 captures them
  export INVENTORY_URL=${INVENTORY_URL}
  export RABBITMQ_HOST=${RABBITMQ_HOST}
  export RABBITMQ_PORT=${RABBITMQ_PORT}
  export RABBITMQ_USER=${RABBITMQ_USER}
  export RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}

  pm2 delete api-gateway 2>/dev/null || true
  pm2 start server.py --name api-gateway --interpreter ${VENV_DIR}/bin/python
  pm2 save
"

# 4. Configure PM2 to start on boot
echo "Setting up PM2 startup script..."
env PATH=$PATH:/usr/bin /usr/local/bin/pm2 startup systemd -u vagrant --hp /home/vagrant