#!/bin/bash

# Prompt for your server address
read -p "Enter your server address: " SERVER_ADDRESS

# Update package list
sudo apt-get update

# Install OpenJDK 17
sudo apt-get install -y openjdk-17-jdk

# Set JAVA_HOME and update PATH in .bashrc
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

# Apply the changes
source ~/.bashrc

# Create log directory for OpenSearch
sudo mkdir -p /var/log/opensearch

# Create OpenSearch directory and navigate into it
sudo mkdir -p /opt/opensearch
cd /opt/opensearch

# Download OpenSearch 2.5.0
sudo wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.5.0/opensearch-2.5.0-linux-x64.tar.gz

# Extract the tar.gz file
sudo tar -xzf opensearch-2.5.0-linux-x64.tar.gz

# Modify OpenSearch configuration
cd /opt/opensearch/opensearch-2.5.0/config

sudo tee opensearch.yml > /dev/null <<EOF
# ======================== OpenSearch Configuration =========================
cluster.name: my-application
node.name: node-1
path.logs: /var/log/opensearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
discovery.seed_hosts: ["$SERVER_ADDRESS"]
plugins.security.disabled: true
EOF

# Create a system user for OpenSearch
sudo useradd -r -s /usr/sbin/nologin opensearch

# Change ownership of OpenSearch installation
sudo chown -R opensearch:opensearch /opt/opensearch

# Start OpenSearch in the foreground
# Start OpenSearch in background and keep it alive for 1 minute
cd /opt/opensearch/opensearch-2.5.0
echo "Starting OpenSearch in background for 60 seconds..."

sudo -u opensearch timeout 60s ./bin/opensearch &

# Wait for OpenSearch to come up
echo "Waiting for OpenSearch to start..."
sleep 20  # Optional: small buffer before first curl

RETRIES=10
until curl -s http://localhost:9200 >/dev/null; do
  ((RETRIES--))
  if [ $RETRIES -le 0 ]; then
    echo "❌ OpenSearch did not respond within expected time."
    exit 1
  fi
  echo "Still waiting..."
  sleep 5
done

echo "✅ OpenSearch is up!"
curl http://localhost:9200
