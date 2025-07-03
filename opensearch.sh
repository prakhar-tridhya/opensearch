#!/bin/bash

# Prompt for your server address
read -p "Enter your server address: " SERVER_ADDRESS

# Exit on error
set -e

echo "🔧 Updating and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk wget tar curl

echo "🧩 Setting JAVA_HOME..."
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

echo "📁 Creating required directories..."
sudo mkdir -p /opt/opensearch
sudo mkdir -p /var/log/opensearch
sudo mkdir -p /opt/opensearch/logs

echo "⬇️ Downloading OpenSearch 2.5.0..."
cd /opt/opensearch
sudo wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.5.0/opensearch-2.5.0-linux-x64.tar.gz
sudo tar -xzf opensearch-2.5.0-linux-x64.tar.gz
sudo rm opensearch-2.5.0-linux-x64.tar.gz

echo "👤 Creating opensearch user..."
sudo useradd -r -s /usr/sbin/nologin opensearch || true
sudo chown -R opensearch:opensearch /opt/opensearch /var/log/opensearch

echo "🛠️ Writing OpenSearch configuration..."
cat <<EOF | sudo tee /opt/opensearch/opensearch-2.5.0/config/opensearch.yml > /dev/null
cluster.name: my-application
node.name: node-1
path.logs: /var/log/opensearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
discovery.seed_hosts: ["$SERVER_ADDRESS"]
plugins.security.disabled: true
EOF

echo "📝 Creating systemd service for OpenSearch..."
cat <<EOF | sudo tee /etc/systemd/system/opensearch.service > /dev/null
[Unit]
Description=OpenSearch Service
After=network.target

[Service]
Type=simple
User=opensearch
Group=opensearch
ExecStart=/opt/opensearch/opensearch-2.5.0/bin/opensearch
Restart=always
LimitNOFILE=65535
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "🚀 Enabling and starting OpenSearch..."
sudo systemctl enable opensearch
sudo systemctl start opensearch

echo "⏳ Waiting for OpenSearch to be ready..."
RETRIES=15
until curl -s http://localhost:9200 >/dev/null; do
  ((RETRIES--))
  if [ $RETRIES -le 0 ]; then
    echo "❌ OpenSearch failed to respond in time."
    journalctl -u opensearch --no-pager | tail -n 20
    exit 1
  fi
  echo "Still waiting..."
  sleep 5
done

echo "✅ OpenSearch is up!"
curl http://localhost:9200
