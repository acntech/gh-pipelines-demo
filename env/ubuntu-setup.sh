#!/bin/bash

# Script to setup a new Ubuntu server for emulating DEV/QA/PROD environments (with Docker and different exposed ports for the
# environments).
#
# Will work on e.g. an Ubuntu Linode (VM) instance with a public IP address.

# Update and install necessary packages
apt-get update
apt-get upgrade -y

# Install UFW (Uncomplicated Firewall) if not already installed
if ! command -v ufw &> /dev/null; then
    apt-get install -y ufw
fi

# Allow SSH on the new port and other required ports
ufw allow 50022/tcp  # SSH
ufw allow 59443/tcp  # Portainer HTTPS
ufw allow 55000/tcp  # Docker Registry
ufw allow 58080/tcp  # Docker Registry UI

# Additional UFW rules
ufw allow 40080/tcp  # Custom port
ufw allow 40081/tcp  # Custom port
ufw allow 40082/tcp  # Custom port

# Enable UFW (without prompting for confirmation)
ufw --force enable

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

# Create the Docker daemon.json file with insecure registry configuration
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["localhost:55000"]
}
EOF

# Restart Docker to apply the new configuration
systemctl restart docker

# Ensure Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    apt-get install -y docker-compose
fi

# Run the docker-compose.yml file in the same directory as this script
if [ -f "$(dirname "$0")/docker-compose.yml" ]; then
    docker-compose -f "$(dirname "$0")/docker-compose.yml" up -d
else
    echo "docker-compose.yml file not found in the script's directory. Skipping docker-compose up."
fi

# Create a new user "ubuntu" with password "admin"
useradd -m -s /bin/bash ubuntu
echo "ubuntu:admin" | chpasswd

# Add "ubuntu" to the sudo group and configure sudoers to not require password for sudo
usermod -aG sudo ubuntu
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add "ubuntu" to the docker group
usermod -aG docker ubuntu

# Configure SSH
sed -i 's/#Port 22/Port 50022/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Create SSH directory for the ubuntu user
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Generate SSH key pair for the ubuntu user
ssh-keygen -t rsa -b 4096 -f /home/ubuntu/.ssh/id_rsa -q -N ""
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa*
cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Restart SSH service to apply changes
systemctl restart sshd

# Extract the public IP address (assumes eth0 is the primary network interface)
IP_ADDRESS=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')

# Display the private SSH key
echo "The private SSH key for the 'ubuntu' user is:"
cat /home/ubuntu/.ssh/id_rsa

# Provide SSH command suggestion with the extracted IP address
echo -e "\nTo connect to this server, follow these steps:"
echo "1. Copy the above private SSH key and save it to a file under your local ~/.ssh/ directory, for example: ~/.ssh/id_rsa"
echo "2. Set the appropriate permissions on the key file: chmod 600 ~/.ssh/id_rsa"
echo -e "3. Use the following SSH command to connect to the server:\n"
echo "   ssh -i ~/.ssh/id_rsa -p 50022 ubuntu@$IP_ADDRESS"

echo -e "\nSetup is complete. SSH is now on port 50022. The 'ubuntu' user can log in with the generated key."
echo -e "The 'ubuntu' user has sudo privileges and is a member of the docker group.\n"
echo -e "An insecure registry is available at http://$IP_ADDRESS:55000 for testing purposes.\n"
echo -e "An (unsecured) registry UI is available at http://$IP_ADDRESS:58080 for managing images.\n"
echo -e "Portainer is available at http://$IP_ADDRESS:59443 for managing Docker containers.\n"
echo -e "Port 40080, 40081, and 40082 are also open for custom services (devops test servers, DEV, QA and PROD respectively).\n"
