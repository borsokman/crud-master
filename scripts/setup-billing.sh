#!/usr/bin/env bash
set -euo pipefail

# 1. Update system and install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv rabbitmq-server postgresql postgresql-contrib libpq-dev nodejs npm
sudo npm install -g pm2

# 2. Setup PostgreSQL
echo "Setting up PostgreSQL database and user..."
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" || true
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || true

# 3. Setup RabbitMQ
echo "Setting up RabbitMQ user and permissions..."
# Enable RabbitMQ management plugin
rabbitmq-plugins enable rabbitmq_management
# Create user, set permissions, and give admin tag
rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASSWORD}" 2>/dev/null || true
rabbitmqctl set_user_tags "${RABBITMQ_USER}" administrator
rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*"

# 4. Setup Python Virtual Environment (As the vagrant user)
echo "Setting up Python environment..."
APP_DIR="/vagrant/srcs/billing-app"
VENV_DIR="/home/vagrant/.venvs/billing-app"

# Create directories and change ownership to vagrant BEFORE creating the venv
mkdir -p /home/vagrant/.venvs
chown -R vagrant:vagrant /home/vagrant/.venvs

# Run venv creation and pip install as the vagrant user
sudo -u vagrant bash -c "
  python3 -m venv ${VENV_DIR}
  ${VENV_DIR}/bin/pip install --upgrade pip
  ${VENV_DIR}/bin/pip install -r ${APP_DIR}/requirements.txt
"

# 5. Start the Application with PM2 (As the vagrant user)
echo "Starting Billing API with PM2..."
# We pass the environment variables directly to the PM2 start command
sudo -u vagrant bash -c "
  cd ${APP_DIR}
  
  # Export variables for this session so PM2 captures them
  export DB_NAME=${DB_NAME}
  export DB_USER=${DB_USER}
  export DB_PASSWORD=${DB_PASSWORD}
  export DB_HOST=${DB_HOST}
  export DB_PORT=${DB_PORT}
  export RABBITMQ_HOST=${RABBITMQ_HOST}
  export RABBITMQ_PORT=${RABBITMQ_PORT}
  export RABBITMQ_USER=${RABBITMQ_USER}
  export RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}

  pm2 delete billing-api 2>/dev/null || true
  pm2 start server.py --name billing-api --interpreter ${VENV_DIR}/bin/python
  pm2 save
"

# 6. Configure PM2 to start on boot
echo "Setting up PM2 startup script..."
env PATH=$PATH:/usr/bin /usr/local/bin/pm2 startup systemd -u vagrant --hp /home/vagrant