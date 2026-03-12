#!/bin/bash

echo "============================================"
echo "☕ Charlie Café DevOps Deployment Starting"
echo "============================================"

# -------------------------------------------------
# STEP 1 — Update System
# -------------------------------------------------

echo "Updating system packages..."
sudo dnf update -y

echo "System update completed."
echo ""

# -------------------------------------------------
# STEP 2 — Install Git
# -------------------------------------------------

echo "Installing Git..."

sudo dnf install git -y

echo "Verifying Git installation..."
git --version

echo ""

# -------------------------------------------------
# STEP 3 — Install Docker
# -------------------------------------------------

echo "Installing Docker..."

sudo dnf install docker -y

echo "Starting Docker service..."
sudo systemctl start docker

echo "Enabling Docker at boot..."
sudo systemctl enable docker

echo "Adding ec2-user to Docker group..."
sudo usermod -aG docker ec2-user

echo "Docker version:"
docker --version

echo ""

# -------------------------------------------------
# STEP 4 — Stop old Docker containers
# -------------------------------------------------

echo "Checking for running containers..."

OLD_CONTAINERS=$(sudo docker ps -q)

if [ ! -z "$OLD_CONTAINERS" ]; then
    echo "Stopping existing containers..."
    sudo docker stop $OLD_CONTAINERS
    sudo docker rm $OLD_CONTAINERS
else
    echo "No running containers found."
fi

echo ""

# -------------------------------------------------
# STEP 5 — Build Docker Image
# -------------------------------------------------

echo "Building Docker image..."

sudo docker build -t devops-lab .

echo "Docker images available:"
sudo docker images

echo ""

# -------------------------------------------------
# STEP 6 — Run Docker Container
# -------------------------------------------------

echo "Running container on port 8080..."

sudo docker run -d -p 8080:80 --name devops-container devops-lab

echo "Running containers:"
sudo docker ps

echo ""

# -------------------------------------------------
# STEP 7 — Install Nginx
# -------------------------------------------------

echo "Installing Nginx..."

sudo dnf install nginx -y

echo "Starting Nginx..."
sudo systemctl start nginx

echo "Enabling Nginx at boot..."
sudo systemctl enable nginx

echo ""

# -------------------------------------------------
# STEP 8 — Configure Nginx Reverse Proxy
# -------------------------------------------------

echo "Configuring Nginx reverse proxy..."

sudo tee /etc/nginx/conf.d/devops.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

echo ""

# -------------------------------------------------
# STEP 9 — Test Nginx Configuration
# -------------------------------------------------

echo "Testing Nginx configuration..."

sudo nginx -t

echo ""

# -------------------------------------------------
# STEP 10 — Restart Nginx
# -------------------------------------------------

echo "Restarting Nginx..."

sudo systemctl restart nginx

echo ""

# -------------------------------------------------
# STEP 11 — Final Verification
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

# -------------------------------------------------
# STEP 12 — Get EC2 Public IP
# -------------------------------------------------

EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "============================================"
echo "✅ Deployment Complete"
echo "============================================"

echo ""
echo "Access your application:"
echo ""
echo "http://$EC2_IP"
echo ""

echo "Docker Container Port:"
echo "http://$EC2_IP:8080"

echo ""
echo "Architecture:"
echo "Browser → Nginx (80) → Docker Container (8080) → PHP → RDS via Secrets Manager"

echo ""
echo "============================================"
echo "☕ Charlie Café DevOps Lab Ready"
echo "============================================"