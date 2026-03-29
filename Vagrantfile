Vagrant.configure("2") do |config|
  # Base box (Linux image)
  config.vm.box = "net9/ubuntu-24.04-arm64"
  config.vm.box_version = "1.1"

  # Gateway VM
  config.vm.define "gateway-vm" do |gateway|
    gateway.vm.hostname = "gateway"
    gateway.vm.network "private_network", ip: "192.168.56.10"
    gateway.vm.provision "shell", path: "scripts/setup-gateway.sh",
    env: {
        "INVENTORY_URL"     => "http://192.168.56.20:8080",
        "RABBITMQ_HOST"     => "192.168.56.30",
        "RABBITMQ_PORT"     => ENV['RABBITMQ_PORT'],
        "RABBITMQ_USER"     => ENV['RABBITMQ_USER'],
        "RABBITMQ_PASSWORD" => ENV['RABBITMQ_PASSWORD']
    }
  end

  # Inventory VM
  config.vm.define "inventory-vm" do |inventory|
    inventory.vm.hostname = "inventory"
    inventory.vm.network "private_network", ip: "192.168.56.20"
    inventory.vm.provision "shell", path: "scripts/setup-inventory.sh",
    env: {
        "DB_NAME"     => ENV['INVENTORY_DB_NAME'],
        "DB_USER"     => ENV['INVENTORY_DB_USER'],
        "DB_PASSWORD" => ENV['INVENTORY_DB_PASSWORD'],
        "DB_HOST"     => ENV['INVENTORY_DB_HOST'],
        "DB_PORT"     => ENV['INVENTORY_DB_PORT']
    }
  end

  # Billing VM
  config.vm.define "billing-vm" do |billing|
    billing.vm.hostname = "billing"
    billing.vm.network "private_network", ip: "192.168.56.30"
    billing.vm.provision "shell", path: "scripts/setup-billing.sh",
    env: {
        "DB_NAME"           => ENV['BILLING_DB_NAME'],
        "DB_USER"           => ENV['BILLING_DB_USER'],
        "DB_PASSWORD"       => ENV['BILLING_DB_PASSWORD'],
        "DB_HOST"           => ENV['BILLING_DB_HOST'],
        "DB_PORT"           => ENV['BILLING_DB_PORT'],
        "RABBITMQ_HOST"     => ENV['RABBITMQ_HOST'],
        "RABBITMQ_PORT"     => ENV['RABBITMQ_PORT'],
        "RABBITMQ_USER"     => ENV['RABBITMQ_USER'],
        "RABBITMQ_PASSWORD" => ENV['RABBITMQ_PASSWORD']
      }
  end
end
