# 🎬 CRUD-MASTER: Movie Streaming Infrastructure

A microservices architecture built with Python, Flask, PostgreSQL, and RabbitMQ, deployed across multiple virtual machines using Vagrant.

# Architecture & Design Choices

- **Microservices Pattern**: The system is split into three distinct components to ensure a clear separation of concerns.
- **API Gateway (192.168.56.10)**: Acts as the single entry point. It proxies HTTP requests to the Inventory API and publishes AMQP messages to the Billing API.
- **Inventory API (192.168.56.20)**: A synchronous RESTful API using Flask and SQLAlchemy to manage a PostgreSQL database (`movies_db`).
- **Billing API (192.168.56.30)**: An asynchronous worker using `pika` that strictly consumes messages from RabbitMQ (`billing_queue`) and writes to PostgreSQL (`billing_db`). No HTTP server is exposed.
- **Process Management**: `pm2` is used across all VMs to daemonize the Python applications and automatically restart them on failure or reboot, ensuring system resilience.
- **Automated Provisioning**: Bash scripts injected via Vagrant handle all dependency installations, database initializations, and process configurations without manual intervention.

# 🛠 Tech Stack

Flask: Lightweight web framework for RESTful services.

SQLAlchemy: ORM for Python-to-PostgreSQL mapping.

PostgreSQL: Relational database for persistent storage.

RabbitMQ: Message broker for decoupled, asynchronous task handling.

PM2: Process manager for daemonizing and auto-restarting services.

Vagrant & VirtualBox: Automated provisioning and environment isolation.

# Build and Run

vagrant up # Create and start all VMs
vagrant status # Show VM status
vagrant ssh <name> # SSH into a VM (e.g., vagrant ssh gateway-vm)
vagrant halt # Stop all VMs
vagrant destroy -f # Delete all VMs

# Verify internal networking from Gateway

vagrant ssh gateway-vm -c "ping -c 2 192.168.56.20"
vagrant ssh gateway-vm -c "curl -s http://192.168.56.20:8080/api/movies"

# Check process status across nodes

vagrant ssh gateway-vm -c "pm2 list"
vagrant ssh inventory-vm -c "pm2 list"
vagrant ssh billing-vm -c "pm2 list"

vagrant ssh gateway-vm -c "pm2 status"
vagrant ssh inventory-vm -c "pm2 status"
vagrant ssh billing-vm -c "pm2 status"

# Smoke test

curl -i http://192.168.56.10:5000/api/movies
curl -i -X POST http://192.168.56.10:5000/api/movies -H "Content-Type: application/json" -d '{"title":"Test","description":"ok"}'
curl -i -X POST http://192.168.56.10:5000/api/billing -H "Content-Type: application/json" -d '{"user_id":"1","number_of_items":"2","total_amount":"30"}'

# Inventory API test:

1. Create movie
   curl -s -X POST http://192.168.56.10:5000/api/movies \
    -H "Content-Type: application/json" \
    -d '{"title":"Inception","description":"Sci-fi"}'

2. List movies
   curl -s http://192.168.56.10:5000/api/movies

3. Get movie id=1
   curl -s http://192.168.56.10:5000/api/movies/1

4. Update movie id=1
   curl -s -X PUT http://192.168.56.10:5000/api/movies/1 \
    -H "Content-Type: application/json" \
    -d '{"title":"Inception Updated","description":"Sci-fi updated"}'

5. Delete movie id=1
   curl -s -X DELETE http://192.168.56.10:5000/api/movies/1

6. Delete all movies
   curl -s -X DELETE http://192.168.56.10:5000/api/movies

# Billing API test (Integration/Resilience Test)

1. Stop billing worker

vagrant ssh billing-vm -c "pm2 stop billing-api"

2. Queue message through gateway (must still succeed, returns 202 Accepted)

curl -s -X POST http://192.168.56.10:5000/api/billing \
 -H "Content-Type: application/json" \
 -d '{"user_id":"3","number_of_items":"5","total_amount":"180"}'

3. Check DB before restart (should NOT include new row yet):

vagrant ssh billing-vm -c "sudo -u postgres psql -d billing_db -c 'SELECT \* FROM orders;'"

4. Start billing worker: vagrant ssh billing-vm -c "pm2 start billing-api"

5. Wait a few seconds, then check DB again. Verify the row has now appeared (proving the message was successfully queued and then processed).

# Crud-Master Repo Tree

```
crud-master
├─ .env
├─ README.md
├─ Vagrantfile
├─ config.yaml
├─ crud-master-diagram.png
├─ scripts
│  ├─ setup-billing.sh
│  ├─ setup-gateway.sh
│  └─ setup-inventory.sh
└─ srcs
   ├─ api-gateway-app
   │  ├─ .env
   │  ├─ app
   │  │  ├─ __init__.py
   │  │  ├─ config.py
   │  │  └─ routes.py
   │  ├─ requirements.txt
   │  └─ server.py
   ├─ billing-app
   │  ├─ .env
   │  ├─ app
   │  │  ├─ __init__.py
   │  │  ├─ consumer.py
   │  │  └─ models.py
   │  ├─ requirements.txt
   │  └─ server.py
   └─ inventory-app
      ├─ .env
      ├─ app
      │  ├─ __init__.py
      │  ├─ models.py
      │  └─ routes.py
      ├─ requirements.txt
      └─ server.py

```
