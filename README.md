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
