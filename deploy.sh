#!/bin/bash

echo "============================================"
echo "☕ Charlie Café DevOps Deployment Starting"
echo "============================================"

# -------------------------------------------------
# VARIABLES
# -------------------------------------------------

REPO_URL="https://github.com/awsrmmustansarjavaid/devops-docker-rds-lab.git"
PROJECT_DIR="/home/ec2-user/devops-docker-rds-lab"

echo ""

# -------------------------------------------------
# STEP 1 — Update System
# -------------------------------------------------

echo "Updating system packages..."
sudo dnf update -y

echo ""

# -------------------------------------------------
# STEP 2 — Install Git
# -------------------------------------------------

echo "Installing Git..."

sudo dnf install git -y

echo "Git version:"
git --version

echo ""

# -------------------------------------------------
# STEP 3 — Clone or Update Repository
# -------------------------------------------------

echo "Checking project repository..."

if [ ! -d "$PROJECT_DIR" ]; then

    echo "Repository not found. Cloning project..."

    git clone $REPO_URL $PROJECT_DIR

else

    echo "Repository already exists."
    echo "Pulling latest updates..."

    cd $PROJECT_DIR
    git pull

fi

cd $PROJECT_DIR

echo "Current directory:"
pwd

echo ""

# -------------------------------------------------
# STEP 4 — Install Docker
# -------------------------------------------------

echo "Installing Docker..."

sudo dnf install docker -y

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker ec2-user

echo "Docker version:"
docker --version

echo ""

# -------------------------------------------------
# STEP 5 — Stop old containers
# -------------------------------------------------

echo "Checking for running containers..."

OLD_CONTAINERS=$(sudo docker ps -q)

if [ ! -z "$OLD_CONTAINERS" ]; then

    echo "Stopping old containers..."

    sudo docker stop $OLD_CONTAINERS
    sudo docker rm $OLD_CONTAINERS

else

    echo "No running containers."

fi

echo ""

# -------------------------------------------------
# STEP 6 — Build Docker Image
# -------------------------------------------------

echo "Building Docker image..."

sudo docker build -t devops-lab .

echo "Docker images:"
sudo docker images

echo ""

# -------------------------------------------------
# STEP 7 — Run Docker Container
# -------------------------------------------------

echo "Running Docker container..."

sudo docker run -d -p 8080:80 --name devops-container devops-lab

echo "Running containers:"
sudo docker ps

echo ""

# -------------------------------------------------
# STEP 8 — Install Nginx
# -------------------------------------------------

echo "Installing Nginx..."

sudo dnf install nginx -y

sudo systemctl start nginx
sudo systemctl enable nginx

echo ""

# -------------------------------------------------
# STEP 9 — Remove Default Nginx Config
# -------------------------------------------------

echo "Removing default Nginx config..."

sudo rm -f /etc/nginx/conf.d/default.conf

echo ""

# -------------------------------------------------
# STEP 10 — Configure Reverse Proxy
# -------------------------------------------------

echo "Creating Nginx reverse proxy config..."

sudo tee /etc/nginx/conf.d/devops.conf > /dev/null <<EOF
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

echo ""

# -------------------------------------------------
# STEP 11 — Test Nginx
# -------------------------------------------------

echo "Testing Nginx configuration..."

sudo nginx -t

echo ""

# -------------------------------------------------
# STEP 12 — Restart Nginx
# -------------------------------------------------

echo "Restarting Nginx..."

sudo systemctl restart nginx

echo ""

# -------------------------------------------------
# STEP 13 — Detect IP Addresses
# -------------------------------------------------

echo "Detecting instance IP addresses..."

PRIVATE_IP=$(hostname -I | awk '{print $1}')

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(curl -s ifconfig.me)
fi

echo ""

# -------------------------------------------------
# STEP 14 — Localhost Verification
# -------------------------------------------------

echo "Testing Nginx locally..."

curl -I http://localhost

echo ""

echo "Testing Docker container..."

curl -I http://localhost:8080

echo ""

# -------------------------------------------------
# STEP 15 — Final System Verification
# -------------------------------------------------

echo "============================================"
echo "🚀 FINAL SYSTEM VERIFICATION"
echo "============================================"

echo ""
echo "Operating System:"
cat /etc/os-release | grep PRETTY_NAME

echo ""
echo "Git Version:"
git --version

echo ""
echo "Docker Version:"
docker --version

echo ""
echo "Running Docker Containers:"
sudo docker ps

echo ""
echo "Docker Images:"
sudo docker images

echo ""
echo "Nginx Status:"
sudo systemctl status nginx --no-pager

echo ""

echo "============================================"
echo "🌐 ACCESS INFORMATION"
echo "============================================"

echo ""
echo "Private IP:"
echo "http://$PRIVATE_IP"

echo ""

echo "Public IP:"
echo "http://$PUBLIC_IP"

echo ""

echo "Docker Direct Port:"
echo "http://$PUBLIC_IP:8080"

echo ""

echo "Localhost Test:"
echo "http://localhost"

echo ""

echo "Architecture:"
echo "Browser → Nginx (80) → Docker (8080) → PHP → RDS → Secrets Manager"

echo ""
echo "============================================"
echo "☕ Charlie Café DevOps Lab Ready"
echo "============================================"