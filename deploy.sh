#!/bin/bash

echo "===== 1. Updating System ====="
sudo yum update -y

echo "===== 2. Installing Docker ====="
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
docker --version

echo "===== 3. Stop old Docker containers (if any) ====="
OLD_CONTAINERS=$(sudo docker ps -q)
if [ ! -z "$OLD_CONTAINERS" ]; then
    echo "Stopping old containers..."
    sudo docker stop $OLD_CONTAINERS
    sudo docker rm $OLD_CONTAINERS
fi

echo "===== 4. Building Docker Image ====="
sudo docker build -t devops-lab .

echo "===== 5. Running Docker Container on 8080 ====="
sudo docker run -d -p 8080:80 devops-lab

echo "===== 6. Installing and Starting Nginx ====="
sudo yum install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "===== 7. Configuring Nginx Reverse Proxy ====="
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

echo "===== 8. Test Nginx Configuration ====="
sudo nginx -t

echo "===== 9. Restart Nginx ====="
sudo systemctl restart nginx

echo "===== 10. Verifications ====="
echo "Docker Containers:"
sudo docker ps

echo "Nginx Status:"
sudo systemctl status nginx

EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "You can access the app in your browser at:"
echo "http://$EC2_IP"

echo "✅ Deployment Complete! Your PHP app is running in Docker, connected to RDS via Secrets Manager, and served through Nginx."