#!/bin/bash
set -e

read -p "Enter Java version (e.g. 17, 21): " JAVA_VERSION
read -p "Enter OpenSearch version (e.g. 2.5.0): " OPENSEARCH_VERSION

SERVER_ADDRESS=$(hostname -I | awk '{print $1}')

sudo apt-get update -qq
sudo apt-get install -y openjdk-${JAVA_VERSION}-jdk wget tar curl

echo "export JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64" >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

sudo mkdir -p /opt/opensearch /var/log/opensearch /opt/opensearch/logs
cd /opt/opensearch
sudo wget -q https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VERSION}/opensearch-${OPENSEARCH_VERSION}-linux-x64.tar.gz
sudo tar -xzf opensearch-${OPENSEARCH_VERSION}-linux-x64.tar.gz
sudo rm opensearch-${OPENSEARCH_VERSION}-linux-x64.tar.gz

sudo useradd -r -s /usr/sbin/nologin opensearch || true
sudo chown -R opensearch:opensearch /opt/opensearch /var/log/opensearch

sudo tee /opt/opensearch/opensearch-${OPENSEARCH_VERSION}/config/opensearch.yml > /dev/null <<EOF
cluster.name: my-application
node.name: node-1
path.logs: /var/log/opensearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
discovery.seed_hosts: ["$SERVER_ADDRESS"]
plugins.security.disabled: true
EOF

sudo tee /etc/systemd/system/opensearch.service > /dev/null <<EOF
[Unit]
Description=OpenSearch Service
After=network.target

[Service]
Type=simple
User=opensearch
Group=opensearch
ExecStart=/opt/opensearch/opensearch-${OPENSEARCH_VERSION}/bin/opensearch
Restart=always
LimitNOFILE=65535
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now opensearch

for i in {1..15}; do
  curl -s http://localhost:9200 && break
  sleep 5
done

curl http://localhost:9200
