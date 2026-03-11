## 🔥 Full DevOps Lab — Charlie Café Project (Beginner → Advanced)

### Goal:

Deploy a PHP app using Docker on EC2, connect to RDS using Secrets Manager, setup Nginx reverse proxy, and automate CI/CD using GitHub Actions.

### Tools & Services:

- AWS EC2

- AWS RDS (MySQL)

- AWS Secrets Manager

- GitHub

- Docker

- Bash scripts for automation

- Nginx reverse proxy

- CI/CD pipeline with GitHub Actions

### Step 0 — Pre-requisites

- AWS account with EC2, RDS, Secrets Manager configured

- EC2 instance running Amazon Linux 2

- RDS database ready:

```
username: cafe_user
password: StrongPassword123
host: cafedb.c03ieya4wc40.us-east-1.rds.amazonaws.com
dbname: cafe_db
```

- Secrets Manager entry for RDS credentials

- GitHub repository for your project

### 1️⃣ — Connect to EC2 and update system

```
ssh -i "Public.pem" ec2-user@ec2-3-239-78-159.compute-1.amazonaws.com
sudo yum update -y
```

### ✅ Verify system updated:

```
sudo yum list updates
```

### 2️⃣ — Install Docker

```
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
docker --version
```

### 3️⃣ — Install Nginx

```
sudo yum install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

### 4️⃣ — Clone your project repo

```
git clone https://github.com/awsrmmustansarjavaid/devops-docker-rds-lab.git
cd devops-docker-rds-lab
sudo chmod +x deploy.sh
```

### 5️⃣  — Write deploy.sh script

Create deploy.sh (final version combines Docker + Nginx + verification):Step 5 — Write deploy.sh script

Create deploy.sh (final version combines Docker + Nginx + verification):

```
#!/bin/bash

echo "===== Updating System ====="
sudo yum update -y

echo "===== Installing Docker ====="
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker

echo "===== Stop old Docker containers ====="
OLD_CONTAINERS=$(sudo docker ps -q)
if [ ! -z "$OLD_CONTAINERS" ]; then
    sudo docker stop $OLD_CONTAINERS
    sudo docker rm $OLD_CONTAINERS
fi

echo "===== Building Docker Image ====="
sudo docker build -t devops-lab .

echo "===== Running Docker Container on 8080 ====="
sudo docker run -d -p 8080:80 devops-lab

echo "===== Installing/Starting Nginx ====="
sudo yum install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "===== Configuring Nginx Reverse Proxy ====="
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

sudo nginx -t
sudo systemctl restart nginx

echo "===== Verification ====="
echo "Docker Containers:"
sudo docker ps
echo "Nginx Status:"
sudo systemctl status nginx
echo "Access app via: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
```

#### Make it executable:

```
sudo chmod +x deploy.sh
```

#### Test deploy.sh locally

```
sudo ./deploy.sh
```

#### ✅ Verify:

- Docker container is running on 8080

- Nginx is running and forwarding port 80 → 8080

- Browser: http://EC2_PUBLIC_IP → app loads and connects to RDS via Secrets Manager

### 6️⃣ — Configure GitHub Actions CI/CD

### 1️⃣ — Add EC2 SSH key as GitHub Secret

- Copy EC2 private key (Public.pem) content

- Go to GitHub → Settings → Secrets → Actions → New repository secret

- Name: EC2_SSH_KEY

- Value: paste the full private key

### 2️⃣  — Create workflow

- Folder:

```
.github/workflows/deploy.yml
```

- Content:

```
name: DevOps Lab CI/CD

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v3

    - name: Set up SSH
      uses: webfactory/ssh-agent@v0.8.1
      with:
        ssh-private-key: ${{ secrets.EC2_SSH_KEY }}

    - name: Copy files to EC2
      run: |
        scp -o StrictHostKeyChecking=no -r * ec2-user@ec2-3-239-78-159.compute-1.amazonaws.com:/home/ec2-user/devops-docker-rds-lab

    - name: Run deploy script on EC2
      run: |
        ssh -o StrictHostKeyChecking=no ec2-user@ec2-3-239-78-159.compute-1.amazonaws.com "cd /home/ec2-user/devops-docker-rds-lab && sudo ./deploy.sh"
```

### 7️⃣ — Test CI/CD

- Edit a file in repo, e.g., index.php → add a test header

```
echo "<h1>CI/CD Test ✅</h1>";
```

- Commit and push:

```
git add .
git commit -m "Test CI/CD workflow"
git push origin main
```

- Go to GitHub → Actions → workflow should run automatically

- Verify: http://EC2_PUBLIC_IP shows updated header

### 8️⃣ — Optional: HTTPS with Nginx

```
sudo yum install certbot python3-certbot-nginx -y
sudo certbot --nginx
```

Follow prompts to secure your domain with SSL

### 9️⃣ — Lab Verification

- Docker container running on 8080 ✅

- Nginx running and reverse proxying port 80 ✅

- EC2 app connects to RDS via Secrets Manager ✅

- GitHub Actions deploy updates automatically ✅

- Browser: http://EC2_PUBLIC_IP shows app ✅

### ✅ Result

This single lab now demonstrates all core DevOps skills:

- AWS EC2 + Docker

- AWS RDS + Secrets Manager

- Bash automation

- Nginx reverse proxy

- GitHub Actions CI/CD

It’s a strong DevOps portfolio project for your resume.
---


