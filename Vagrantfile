require 'dotenv'
Dotenv.load

Vagrant.configure("2") do |config|
  # Base box (Linux image)
  config.vm.box = "ubuntu/focal64"

  # Gateway VM
  config.vm.define "gateway-vm" do |gateway|
    gateway.vm.hostname = "gateway"
    gateway.vm.network "private_network", ip: "192.168.1.10"
    gateway.vm.provision "shell", path: "scripts/setup-gateway.sh"
  end

  # Inventory VM
  config.vm.define "inventory-vm" do |inventory|
    inventory.vm.hostname = "inventory"
    inventory.vm.network "private_network", ip: "192.168.1.20"
    inventory.vm.provision "shell", path: "scripts/setup-inventory.sh",
    env: {
        "DB_NAME"     => ENV['DB_NAME'],
        "DB_USER"     => ENV['DB_USER'],
        "DB_PASSWORD" => ENV['DB_PASSWORD']
    }
  end

  # Billing VM
  config.vm.define "billing-vm" do |billing|
    billing.vm.hostname = "billing"
    billing.vm.network "private_network", ip: "192.168.1.30"
    billing.vm.provision "shell", path: "scripts/setup-billing.sh",
    env: {
        "DB_NAME"     => ENV['DB_NAME'],
        "DB_USER"     => ENV['DB_USER'],
        "DB_PASSWORD" => ENV['DB_PASSWORD']
      }
  end
end
