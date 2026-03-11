#!/bin/bash

echo "===================="
echo "1️⃣ Updating system..."
echo "===================="
sudo yum update -y

echo "===================="
echo "2️⃣ Installing Docker..."
echo "===================="
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker

echo "===================="
echo "3️⃣ Installing Nginx..."
echo "===================="
sudo yum install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "===================="
echo "4️⃣ Building Docker Image..."
echo "===================="
sudo docker build -t devops-lab .

echo "===================="
echo "5️⃣ Stopping any existing Docker container on port 8080..."
echo "===================="
EXISTING_CONTAINER=$(sudo docker ps -q --filter "ancestor=devops-lab")
if [ ! -z "$EXISTING_CONTAINER" ]; then
    echo "Stopping existing container(s)..."
    sudo docker stop $EXISTING_CONTAINER
    sudo docker rm $EXISTING_CONTAINER
fi

echo "===================="
echo "6️⃣ Running Docker Container on port 8080..."
echo "===================="
sudo docker run -d -p 8080:80 devops-lab

echo "===================="
echo "7️⃣ Verification Checks"
echo "===================="

# Check Docker service
echo -n "Checking Docker service... "
if systemctl is-active --quiet docker; then
    echo "✅ Docker service is running"
else
    echo "❌ Docker service is NOT running"
fi

# Check Docker container
echo -n "Checking Docker container... "
CONTAINER_STATUS=$(sudo docker ps --filter "ancestor=devops-lab" --format "{{.Status}}")
if [ ! -z "$CONTAINER_STATUS" ]; then
    echo "✅ Docker container is running: $CONTAINER_STATUS"
else
    echo "❌ Docker container is NOT running"
fi

# Check Nginx service
echo -n "Checking Nginx service... "
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is NOT running"
fi

echo "===================="
echo "✅ Deployment Complete!"
echo "Access your app via:"
echo "http://EC2_PUBLIC_IP"
echo "Docker container port: 8080 (reverse proxied via Nginx port 80)"
echo "===================="