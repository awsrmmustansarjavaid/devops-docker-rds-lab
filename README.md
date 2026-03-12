# 🔥 Full DevOps Lab —  ☕ Charlie Café DevOps Project Lab (Beginner → Advanced)

## Docker + RDS + Secrets Manager + Nginx + CI/CD

### For Amazon Linux 2023

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

### 1️⃣ Charlie Café Project DOC

### 1️⃣ Dockerfile

Place this in the root of your repo (devops-docker-rds-lab/Dockerfile):

```
# Use official PHP + Apache image
FROM php:8.2-apache

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    && docker-php-ext-install mysqli

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Copy app code into Apache root
COPY app/ /var/www/html/

# Set working directory
WORKDIR /var/www/html

# Install AWS SDK for PHP (for Secrets Manager access)
RUN composer require aws/aws-sdk-php

# Expose port 80
EXPOSE 80
```

### 2️⃣ index.php

Create folder app/ inside your repo and add index.php:

```
<?php
require 'vendor/autoload.php';

use Aws\SecretsManager\SecretsManagerClient;
use Aws\Exception\AwsException;

// AWS Region
$region = 'us-east-1';
$secretName = 'CafeDevDBSM'; // Your Secrets Manager secret name

// Create Secrets Manager client
$client = new SecretsManagerClient([
    'version' => 'latest',
    'region'  => $region,
]);

try {
    $result = $client->getSecretValue([
        'SecretId' => $secretName,
    ]);
    $secret = json_decode($result['SecretString'], true);

    $host = $secret['host'];
    $dbname = $secret['dbname'];
    $username = $secret['username'];
    $password = $secret['password'];

    $mysqli = new mysqli($host, $username, $password, $dbname);

    if ($mysqli->connect_errno) {
        echo "Failed to connect to MySQL: " . $mysqli->connect_error;
        exit();
    }

    echo "<h1>DevOps Lab Connected to RDS Successfully ✅</h1>";

    $query = $mysqli->query("SELECT NOW() AS time");
    $row = $query->fetch_assoc();
    echo "<p>Server time: " . $row['time'] . "</p>";

    $mysqli->close();
} catch (AwsException $e) {
    echo "Error retrieving secret: " . $e->getMessage();
}
```

### 3️⃣ — Create deploy.sh (Amazon Linux 2023 version)

#### ✅ Replace with this working version:

```
#!/bin/bash

echo "Updating system"
sudo dnf update -y

echo "Installing Docker"
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker

echo "Stopping old containers"
OLD=$(sudo docker ps -q)

if [ ! -z "$OLD" ]; then
 sudo docker stop $OLD
 sudo docker rm $OLD
fi

echo "Building Docker image"
sudo docker build -t devops-lab .

echo "Running container"
sudo docker run -d -p 8080:80 devops-lab

echo "Installing Nginx"
sudo dnf install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Configuring reverse proxy"

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

echo "Testing Nginx"
sudo nginx -t

echo "Restarting Nginx"
sudo systemctl restart nginx

echo "Deployment complete"

EC2IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "Access your app:"
echo "http://$EC2IP"
```

#### ✅ Make Script Executable

```
sudo chmod +x deploy.sh
```

#### ✅ Run:

```
sudo ./deploy.sh
```



### 3️⃣ Folder Structure

```
devops-docker-rds-lab/
│
├── Dockerfile
├── deploy.sh
├── README.md
├── .github/
│   └── workflows/
│       └── deploy.yml
└── app/
    └── index.php
```

### ✅ With this structure, your deploy.sh, Dockerfile, and index.php all work together.

- Docker builds the PHP app

- index.php reads Secrets Manager credentials to connect to RDS

- Nginx reverse proxy routes port 80 → Docker container

### 2️⃣ Charlie Café Project Configurations

### 1️⃣ — Launch EC2 Instance

- Create an EC2 instance in Amazon Web Services.

- Settings:

| Setting        | Value             |
| -------------- | ----------------- |
| AMI            | Amazon Linux 2023 |
| Instance       | t2.micro          |
| Key pair       | Public.pem        |
| Security Group | Allow 22, 80      |

- Ports required:

| Port | Purpose          |
| ---- | ---------------- |
| 22   | SSH              |
| 80   | Web              |
| 8080 | Docker container |

### 2️⃣ Connect to EC2

- From your local computer:

```
ssh -i Public.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

#### Example:

```
ssh -i Public.pem ec2-user@3.239.78.159
```

### 3️⃣ Update Amazon Linux 2023

- Amazon Linux 2023 uses dnf.

```
sudo dnf update -y
```

#### ✅ Verify:

```
cat /etc/os-release
```

### ✅ Expected:

```
Amazon Linux 2023
```

### 2️⃣ Install Git

```
sudo dnf install git -y
```

#### ✅ Verify:

```
git --version
```

### 3️⃣ Install Docker

#### 1️⃣ Install Docker:

```
sudo dnf install docker -y
```

#### 2️⃣ Start Docker:

```
sudo systemctl start docker
```

#### 3️⃣ Enable Docker at boot:

```
sudo systemctl enable docker
```

#### 4️⃣ Check Docker:

```
docker --version
```

#### ✅ Example output:

```
Docker version 24.x
```

### 4️⃣ Allow ec2-user to run Docker

#### 1️⃣ Without sudo:

```
sudo usermod -aG docker ec2-user
```

#### 2️⃣ Reload group permissions:

```
newgrp docker
```

#### 3️⃣ Test Docker:

```
docker run hello-world
```

#### ✅ Expected:

```
Hello from Docker!
```

### 5️⃣ — Install Nginx

#### 1️⃣ Install Nginx:

```
sudo dnf install nginx -y
```

#### 2️⃣ Start Nginx:

```
sudo systemctl start nginx
```

#### 3️⃣ Enable at boot:

```
sudo systemctl enable nginx
```

#### 4️⃣ Verify:

```
sudo systemctl status nginx
```

#### 5️⃣ Open browser:

```
http://EC2_PUBLIC_IP
```

You should see Nginx welcome page.

### 6️⃣ — Clone Your GitHub Repository

#### ✅ Your repo example:

```
devops-docker-rds-lab
```

#### 1️⃣ Clone:

```
git clone https://github.com/awsrmmustansarjavaid/devops-docker-rds-lab.git
```

#### 2️⃣ Enter project folder:

```
cd devops-docker-rds-lab
```

#### 3️⃣ Verify:

```
ls
```

#### ✅ Expected:

```
Dockerfile
deploy.sh
app
README.md
.github
```

### ✅ Verify Folder Structure

Must look like this:

```
devops-docker-rds-lab
│
├── Dockerfile
├── deploy.sh
│
├── app
│   └── index.php
│
└── .github
    └── workflows
        └── deploy.yml
```

### 7️⃣ — Build Docker Image

#### 1️⃣ Run:

```
docker build -t devops-lab .
```

#### 2️⃣ Verify image:

```
docker images
```

#### ✅ Expected:

```
devops-lab
```

### 8️⃣ — Run Docker Container

#### 1️⃣ Run container on port 8080:

```
docker run -d -p 8080:80 devops-lab
```

#### 2️⃣ Check running containers:

```
docker ps
```

#### ✅ Expected:

```
PORTS
0.0.0.0:8080->80
```

### 8️⃣ — Test Container

#### 1️⃣ Open browser:

```
http://EC2_PUBLIC_IP:8080
```

#### ✅ Expected Page:

```
DevOps Lab Connected to RDS Successfully
```

### 9️⃣ — Configure Nginx Reverse Proxy

#### 1️⃣ Create config file:

```
sudo nano /etc/nginx/conf.d/devops.conf
```

#### 2️⃣ Paste:

```
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 3️⃣ Save:

```
CTRL+O
ENTER
CTRL+X
```

### 🔟 — Verification

#### 1️⃣ Test Nginx Config

```
sudo nginx -t
```

#### ✅ Expected:

```
syntax is ok
test is successful
```

#### 2️⃣ — Restart Nginx

```
sudo systemctl restart nginx
```

#### 3️⃣ — Test Reverse Proxy

#### ✅ Open browser:

```
http://EC2_PUBLIC_IP
```

#### ✅ Now:

```
Port 80 → Nginx → Docker → PHP App
```

### 4️⃣ — Verify Secrets Manager Access

#### ✅ Your PHP code reads secret:

```
CafeDevDBSM
```

- From AWS Secrets Manager.

- Your EC2 must have IAM Role.

#### ✅ Attach IAM Role with permission:

```
SecretsManagerReadWrite
```

#### ✅ or minimal policy:

```
secretsmanager:GetSecretValue
```








### 5️⃣  — Write deploy.sh script

Create deploy.sh (final version combines Docker + Nginx + verification):Step 5 — Write deploy.sh script

Create deploy.sh (final version combines Docker + Nginx + verification):

```
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
```

#### ✅ What this script does

- Updates your EC2 system

- Installs Docker (if not installed)

- Stops and removes any old containers to prevent port conflicts

- Builds the Docker image for your PHP app

- Runs the Docker container on port 8080

- Installs Nginx and enables it to start on boot

- Configures Nginx reverse proxy (port 80 → Docker 8080)

- Tests Nginx configuration for errors

- Restarts Nginx

- Prints a full verification: Docker containers, Nginx status, and browser URL

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

- Browser: http://EC2_PUBLIC_IP → app loads and DevOps Lab Connected to RDS Successfully ✅

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


