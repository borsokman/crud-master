Setup (MacOS):

1. Python 3 + Flask + SQLAlchemy

bash

# Install Python 3 via Homebrew if not already done

brew install python

# Create and activate a virtualenv

python3 -m venv .venv
source .venv/bin/activate

# Install Flask + SQLAlchemy + PostgreSQL driver

pip install Flask
pip install Flask-SQLAlchemy
pip install psycopg2-binary
pip install python-dotenv

2. PostgreSQL (on Apple Silicon is the same as Intel)

bash
brew install postgresql

brew services start postgresql

# Create a dev DB and user

createdb myapp
psql postgres -c "CREATE USER myappuser WITH PASSWORD 'password';"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE myapp TO myappuser;"

3. RabbitMQ

bash
brew install rabbitmq

brew services start rabbitmq

# Optional: enable web UI (default: http://localhost:15672, user: guest, pw: guest)

brew services stop rabbitmq
brew services start rabbitmq -- --load-plugins rabbitmq_management

4. Postman (or CLI alternative)

   Postman (GUI):

bash
brew install --cask postman

# then launch from Finder → Applications → Postman

    CLI alternative (httpie):

bash
brew install httpie

# or just use built‑in curl

5. VirtualBox (M3/Apple Silicon)

   From Homebrew (if available):

bash
brew install --cask virtualbox

    If that fails, download the Apple Silicon version from Oracle’s site (VirtualBox 7.x for M1/M2/M3) and install it from the .dmg.

6. Vagrant (on Apple Silicon)

bash
brew install --cask vagrant

Then in a project folder:

bash
vagrant init ubuntu/jammy64 # Ubuntu 22.04, works on Apple Silicon under VirtualBox
vagrant up
vagrant ssh

Vagrant Basic Commands:

vagrant up # Create and start all VMs
vagrant status # Show VM status
vagrant ssh <name> # SSH into a VM (e.g., vagrant ssh gateway-vm)
vagrant halt # Stop all VMs
vagrant destroy # Delete all VMs

vagrant halt
vagrant destroy -f
vagrant up

Flask
A lightweight Node.js web framework for building REST APIs and web servers. Handles routing, middleware, and HTTP request/response management.

SQLAlchemy
An ORM (Object-Relational Mapping) library for Node.js. Maps database tables to JavaScript objects, allowing you to interact with databases using JavaScript instead of raw SQL.

PostgreSQL
A relational database management system (RDBMS). Stores structured data in tables with relationships. One of the most reliable and feature-rich open-source databases.

RabbitMQ
A message broker. Enables asynchronous communication between applications by queuing messages. Services send/receive messages without direct connection—useful for decoupled systems and real-time processing.

Postman
A GUI tool for testing APIs. Send HTTP requests (GET, POST, PUT, DELETE), inspect responses, and organize API workflows. Simplifies API development and debugging.

VirtualBox
A virtualization software. Creates virtual machines—isolated computing environments running different operating systems on a single physical machine. Used for testing and development isolation.

How they fit together (typical stack):
Flask – Build your API server
SQLAlchemy – Interact with PostgreSQL database
PostgreSQL – Store your data
RabbitMQ – Handle asynchronous tasks/messaging
Postman – Test your API endpoints
VirtualBox – Run the entire stack in an isolated environment

VM checklist commands:

Ping/Curl test
vagrant ssh gateway-vm -c "ping -c 2 192.168.56.20"
vagrant ssh gateway-vm -c "ping -c 2 192.168.56.30"
vagrant ssh gateway-vm -c "curl -s http://192.168.56.20:8080/api/movies"

PM2 status on all VMs
vagrant ssh gateway-vm -c "sudo pm2 list"
vagrant ssh inventory-vm -c "sudo pm2 list"
vagrant ssh billing-vm -c "sudo pm2 list"

API test set:

# 1) Create movie

curl -s -X POST http://192.168.56.10:5000/api/movies \
 -H "Content-Type: application/json" \
 -d '{"title":"Inception","description":"Sci-fi"}'

# 2) List movies

curl -s http://192.168.56.10:5000/api/movies

# 3) Get movie id=1

curl -s http://192.168.56.10:5000/api/movies/1

# 4) Update movie id=1

curl -s -X PUT http://192.168.56.10:5000/api/movies/1 \
 -H "Content-Type: application/json" \
 -d '{"title":"Inception Updated","description":"Sci-fi updated"}'

# 5) Delete movie id=1

curl -s -X DELETE http://192.168.56.10:5000/api/movies/1

# 6) Delete all movies

curl -s -X DELETE http://192.168.56.10:5000/api/movies

# Stop billing worker

vagrant ssh billing-vm -c "sudo pm2 stop billing-api"

# Queue message through gateway (must still succeed)

curl -s -X POST http://192.168.56.10:5000/api/billing \
 -H "Content-Type: application/json" \
 -d '{"user_id":"3","number_of_items":"5","total_amount":"180"}'

# Check DB before restart (should NOT include new row yet)

vagrant ssh billing-vm -c "sudo -u postgres psql -d billing_db -c 'SELECT \* FROM orders;'"

# Start billing worker

vagrant ssh billing-vm -c "sudo pm2 start billing-api"

# Wait a few seconds, then check DB again (row should appear)

vagrant ssh billing-vm -c "sudo -u postgres psql -d billing_db -c 'SELECT \* FROM orders;'"

Before any Vagrant command, export env vars:
set -a
source .env
set +a
vagrant up
