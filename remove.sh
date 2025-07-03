#!/bin/bash

# Prompt for confirmation
read -p "This will undo OpenSearch installation and remove all related files. Are you sure? (y/n): " CONFIRMATION

if [[ "$CONFIRMATION" != "y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Undoing OpenSearch installation..."

# 1. Remove OpenJDK 17
echo "Removing OpenJDK 17..."
sudo apt-get remove --purge -y openjdk-17-jdk
sudo apt-get autoremove -y

# 2. Remove JAVA_HOME and PATH modifications from .bashrc
echo "Removing JAVA_HOME and PATH modifications from .bashrc..."
sed -i '/export JAVA_HOME=.*openjdk.*$/d' ~/.bashrc
sed -i '/export PATH=.*\$JAVA_HOME.*$/d' ~/.bashrc

# Reload .bashrc to apply changes
source ~/.bashrc

# 3. Remove OpenSearch directories and logs
echo "Removing OpenSearch directories..."
sudo rm -rf /opt/opensearch
sudo rm -rf /var/log/opensearch

# 4. Remove OpenSearch configuration changes
echo "Removing OpenSearch configuration file..."
sudo rm -f /opt/opensearch/opensearch-2.5.0/config/opensearch.yml

# 5. Remove the opensearch system user
echo "Removing the opensearch system user..."
sudo userdel -r opensearch

echo "Undo process complete!"
