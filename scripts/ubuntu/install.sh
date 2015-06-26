#!/bin/bash
set -e

# Read the address to join from the file we provisioned
JOIN_ADDRS=$(cat /tmp/consul-server-addr | tr -d '\n')

echo "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y unzip

echo "Fetching Consul..."
cd /tmp
wget https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip -O consul.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
sudo chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/service

echo "Installing Upstart service..."
sudo mv /tmp/upstart.conf /etc/init/consul.conf
