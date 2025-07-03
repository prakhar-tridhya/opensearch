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
cd /opt/opensearch/opensearch-2.5.0
echo "Starting OpenSearch in foreground. Use another terminal to run: curl http://localhost:9200"
sudo -u opensearch ./bin/opensearch
