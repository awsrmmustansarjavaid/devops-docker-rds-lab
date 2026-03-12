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

### Architecture of Lab

```
GitHub
   │
   │ push
   ▼
CI/CD Workflow
   │
   ▼
EC2 Instance
   │
   ├── Docker Container
   │        │
   │        ▼
   │      PHP App
   │        │
   │        ▼
   │   AWS Secrets Manager
   │        │
   │        ▼
   │       RDS
   │
   ▼
Nginx Reverse Proxy
   │
   ▼
Browser
```

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

#### ✅ This script now:

✔ installs Git

✔ clones repo automatically

✔ pulls updates if repo exists

✔ installs Docker

✔ builds container

✔ installs Nginx

✔ fixes nginx conflict

✔ detects public + private IP

✔ tests localhost

✔ prints final verification

#### ✅ Replace with this working version (Fully Automatic):

```
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
```

#### ✅ Make Script Executable

```
sudo chmod +x deploy.sh
```

#### ✅ Run:

```
sudo ./deploy.sh
```

#### ✅ The script will now automatically:

1️⃣ Install Git

2️⃣ Clone repo

3️⃣ Build Docker image

4️⃣ Run container

5️⃣ Configure Nginx

6️⃣ Print working URLs

#### ✅ Example Final Output

```
Public IP:
http://3.239.xxx.xxx

Docker Direct Port:
http://3.239.xxx.xxx:8080
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

### 1️⃣ — RDS & Secret Manager Configuration

#### 1️⃣ Create DB Subnet Group

- AWS Console → RDS → Subnet groups → Create

- Name: CafeRDSSubnetGroup

- VPC: CafeDevVPC

- Subnets: PRIVATE subnets (2 AZs)

- ✔️ Create

#### 2️⃣ Default Security Group

- Name: charlie-default-sg

- Attached to: RDS, any EC2/other resources

- Inbound Rules:

| Type         | Protocol | Port Range | Source                                              |
| ------------ | -------- | ---------- | --------------------------------------------------- |
| SSH          | TCP      | 22         | 0.0.0.0/0 (or your IP)                              |
| HTTP         | TCP      | 80         | 0.0.0.0/0                                           |
| HTTPS        | TCP      | 443        | 0.0.0.0/0                                           |
| MySQL/Aurora | TCP      | 3306       | 0.0.0.0/0                                           |
| ALL TCP      | TCP      | 0-65535    | 0.0.0.0/0                                           |

- Outbound Rules:

  - All traffic allowed (default)

#### 3️⃣ Create RDS Instance

- RDS → Databases → Create database

- Engine: MySQL (or MariaDB)

- Template: Free tier

- DB identifier: cafedb

- Username: cafe_user

- Password: StrongPassword123

- VPC: CafeDevVPC

- Subnet group: CafeRDSSubnetGroup

- Public access: ❌ No

- Security group: CafeRDS-SG

- Backup: Enabled

- ✔️ Create database ⏳

#### 4️⃣ Store DB Credentials in Secrets Manager

- Go to Secrets Manager → Store a new secret

- Type: Other type of secret → Key/Value

| Key      | Value              |
|----------|--------------------|
| username | cafe_user          |
| password | StrongPassword123  |
| host     | RDS endpoint       |
| dbname   | cafe_db            |

- Retrieve Secret ARN for later use in the app

### ✅ JSON Key/Value

```
{
  "username": "cafe_user",
  "password": "StrongPassword123",
  "host": "your-rds-endpoint.amazonaws.com",
  "dbname": "cafe_db"
}
```

#### ✅  Replace These Values

- username → cafe_user (your DB user)

- password → StrongPassword123 (your real DB password)

- host → your RDS endpoint (example: cafedb.xxxxxx.us-east-1.rds.amazonaws.com)

- dbname → cafe_db

#### Example With Real Format

```
{
  "username": "cafe_user",
  "password": "StrongPassword123",
  "host": "cafedb.abc123xyz.us-east-1.rds.amazonaws.com",
  "dbname": "cafe_db"
}
```

### ✅ Secret Name

```
CafeDevDBSM
```

### ✅ After Creating the Secret

Copy the Secret ARN. It will look like:

```
arn:aws:secretsmanager:us-east-1:123456789012:secret:CafeDevDBSM-xxxxx
```

#### ✅ You will use this ARN inside your AWS Lambda code to retrieve the database credentials.

### 2️⃣ — Launch EC2 Instance

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

### 3️⃣ Update & Installation Amazon Linux 2023

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

### 6️⃣ — Install MariaDB client

```
sudo dnf install -y mariadb105
```

#### ✅ Verify mysql:

```
mysql --version
```

#### ✅ Login to MariaDB:

```
mysql -h <rds-endpoint> -u cafe_user -p
```

or

#### 🛠️ BASH SCRIPT (Safe RDS Connection)
> #### 📄 connect-rds.sh

```
sudo nano connect-rds.sh
```

[connect-rds.sh](./connect-rds.sh)

```
sudo chmod +x connect-rds.sh
```

```
sudo ./connect-rds.sh
```

#### ✅ Features Added:

- MariaDB installation for Amazon Linux 2023 with version check

- AWS Secrets Manager integration for secure DB credentials

- Database creation (cafe_db)

- Random table creation (employees) with sample rows

- Verification queries to check table creation and inserted data

- Full error checking with exit codes
 
### ✅ Method 2 Dockerized ( Recommanded)

Instead of installing mariadb105 directly on your EC2, you can run the MariaDB client inside a Docker container.

#### Benefits:

- No dependency on EC2 OS package versions

- Easily portable across environments

- Cleaner, isolated execution

### 1️⃣ Use Dockerized MariaDB Client (Optional but Cleaner)

#### Example Command in Script:

```
docker run --rm mariadb:10.11.6 mariadb -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
```

This runs MariaDB client temporarily just for the command.

### 2️⃣  Dynamic Random Table & Data Creation

Instead of hardcoding sample data, generate random table rows in Bash:

```
TABLE_NAME="employees"
ROWS=5

for i in $(seq 1 $ROWS); do
  NAME="Employee_$RANDOM"
  ROLE="Role_$((RANDOM % 5 + 1))"
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" $DB_NAME \
        -e "INSERT INTO $TABLE_NAME (name, role) VALUES ('$NAME', '$ROLE');"
done
```

✅ This makes your script look more like real DevOps automation, generating data dynamically.

### 3️⃣ Add Logging for Each Step

Add timestamps and log messages to track execution:

```
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Installing MariaDB client..."
```

This is standard for production scripts.

### 4️⃣ Verify Table & Data After Creation

Already included in your script:

```
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SELECT * FROM $TABLE_NAME;"
```

You can also fail the script if the verification fails:

```
if [[ $? -ne 0 ]]; then
  log "❌ Table verification failed"
  exit 1
fi
```

### 5️⃣ Optional: Use AWS Parameter for DB Name

Instead of hardcoding cafe_db, use an environment variable or script argument:

```
DB_NAME="${1:-cafe_db}"
```

This allows the script to be reused for multiple databases.

### 🌐 Bash Script Fully Dockerized

This bash script fully Dockerized for MariaDB client with full comments, logging, random table/data creation, and verification. This will make it look “Senior DevOps level.”

#### ✅ Here’s the complete final Dockerized version:

```
#!/bin/bash

# ==========================================================
# CHARLIE CAFÉ DOCKERIZED MARIADB SETUP SCRIPT
# ==========================================================
# This script uses Docker to run MariaDB client commands
# against an AWS RDS instance. It:
# 1️⃣ Fetches DB credentials from AWS Secrets Manager
# 2️⃣ Creates a database
# 3️⃣ Creates a random table with sample data
# 4️⃣ Verifies table and data creation
# Benefits: No need to install MariaDB client on EC2,
# fully portable, clean, production-style automation.
# ==========================================================

# ===============================
# CONFIGURATION
# ===============================

SECRET_ID="CafeDevDBSM"
AWS_REGION="us-east-1"
DB_NAME="cafe_db"
TABLE_NAME="employees"
ROWS=5  # Number of random sample rows to insert

# ===============================
# LOGGING FUNCTION
# ===============================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ===============================
# CHECK DOCKER
# ===============================

if ! command -v docker &> /dev/null; then
    log "❌ Docker not installed. Please install Docker first."
    exit 1
fi

log "✅ Docker is installed"

# ===============================
# FETCH RDS CREDENTIALS
# ===============================

log "🔹 Fetching RDS credentials from Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text)

DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')
DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host')

# ===============================
# VALIDATE CREDENTIALS
# ===============================

if [[ -z "$DB_USER" || -z "$DB_PASS" || -z "$DB_HOST" ]]; then
    log "❌ Failed to retrieve database credentials"
    exit 1
fi

log "✅ RDS credentials retrieved successfully"

# ===============================
# CREATE DATABASE
# ===============================

log "🔹 Creating database '$DB_NAME'..."
docker run --rm mariadb:10.11.6 \
    mariadb -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" \
    -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

if [[ $? -ne 0 ]]; then
    log "❌ Failed to create database $DB_NAME"
    exit 1
fi
log "✅ Database created successfully"

# ===============================
# CREATE TABLE
# ===============================

log "🔹 Creating table '$TABLE_NAME'..."
docker run --rm mariadb:10.11.6 \
    mariadb -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" $DB_NAME \
    -e "CREATE TABLE IF NOT EXISTS $TABLE_NAME (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(50) NOT NULL,
            role VARCHAR(50),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );"

if [[ $? -ne 0 ]]; then
    log "❌ Failed to create table $TABLE_NAME"
    exit 1
fi
log "✅ Table created successfully"

# ===============================
# INSERT RANDOM SAMPLE DATA
# ===============================

log "🔹 Inserting $ROWS random sample rows..."
for i in $(seq 1 $ROWS); do
    NAME="Employee_$RANDOM"
    ROLE="Role_$((RANDOM % 5 + 1))"
    docker run --rm mariadb:10.11.6 \
        mariadb -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" $DB_NAME \
        -e "INSERT INTO $TABLE_NAME (name, role) VALUES ('$NAME', '$ROLE');"
done
log "✅ Sample data inserted successfully"

# ===============================
# VERIFY TABLE & DATA
# ===============================

log "🔹 Verifying table and data..."
docker run --rm mariadb:10.11.6 \
    mariadb -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" $DB_NAME \
    -e "SHOW TABLES; SELECT * FROM $TABLE_NAME;"

if [[ $? -eq 0 ]]; then
    log "🎉 Charlie Café Dockerized MariaDB setup complete!"
else
    log "❌ Verification failed"
    exit 1
fi
```

#### ✅ Key Features of This Script

- Dockerized MariaDB client → No OS dependencies

- AWS Secrets Manager integration → Secure credentials

- Random table and sample data → Realistic DevOps testing

- Logging with timestamps → Production-style traceability

- Full verification → Shows table and sample data at the end

- Error handling → Script exits on any failure

### ✅ upgraded Docker Compose support

Perfect! Now we’ll upgrade your script to use Docker Compose so it can:

- Spin up a local MariaDB container (optional, for testing/dev)

- Connect to your AWS RDS instance using secrets

- Create database, table, random data, and verify everything

- Keep it fully production-style with logging and comments

### ✅ Here’s a full Docker Compose + Bash script setup for your Charlie Café lab.

### ✅ How to Install Docker Compose on Amazon Linux 2023

### Step 1 — Create the plugin directory

```
sudo mkdir -p /usr/local/lib/docker/cli-plugins
```

### Step 2 — Download the Docker Compose binary

```
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
```

This downloads the latest Docker Compose v2 binary for your architecture.

### Step 3 — Make it executable

```
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

### Step 4 — Verify installation

```
docker compose version
```

If everything is correct, this will show the installed Docker Compose version and confirm it works with the docker compose syntax.

> #### Notice: no dash between docker and compose now. You run it as docker compose (v2 style), not docker-compose.

### Step 5: Update Your Script to Use New Docker Compose Command

In your bash script, replace:

```
docker-compose up -d
```

with:

```
docker compose up -d
```

And anywhere else you use docker-compose, replace with docker compose.

### Step 6: Create Docker Compose File (docker-compose.yml)

```
version: '3.9'

services:
  mariadb-client:
    image: mariadb:10.11.6
    container_name: mariadb-client
    restart: "no"
    entrypoint: ["tail", "-f", "/dev/null"]  # keep container running for bash exec
```

#### Explanation:

- We only need the MariaDB client, not a full server.

- Container stays alive so you can exec commands from the bash script.

### Step 7: Docker Compose + Bash Script (Recommanded)

```
#!/bin/bash

# ==========================================================
# CHARLIE CAFÉ DOCKER COMPOSE + MARIADB SETUP SCRIPT
# ==========================================================
# This script:
# 1️⃣ Installs Docker Compose if missing (Amazon Linux 2023)
# 2️⃣ Starts a MariaDB client container via Docker Compose
# 3️⃣ Fetches AWS RDS credentials from Secrets Manager
# 4️⃣ Creates database, table, inserts random data
# 5️⃣ Verifies creation
# ==========================================================

# ===============================
# CONFIGURATION
# ===============================
SECRET_ID="CafeDevDBSM"
AWS_REGION="us-east-1"
DB_NAME="cafe_db"
TABLE_NAME="employees"
ROWS=5

# ===============================
# LOGGING FUNCTION
# ===============================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ===============================
# CHECK DOCKER
# ===============================
if ! command -v docker &> /dev/null; then
    log "❌ Docker not installed."
    exit 1
fi

# ===============================
# CHECK & INSTALL DOCKER COMPOSE
# ===============================
if ! docker compose version &> /dev/null; then
    log "🔹 Docker Compose not found. Installing..."
    
    # Step 1 — Create plugin directory
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    
    # Step 2 — Download Docker Compose binary
    sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    
    # Step 3 — Make it executable
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    
    # Step 4 — Verify installation
    if docker compose version &> /dev/null; then
        log "✅ Docker Compose installed successfully"
    else
        log "❌ Docker Compose installation failed"
        exit 1
    fi
else
    log "✅ Docker Compose already installed"
fi

# ===============================
# START DOCKER COMPOSE SERVICE
# ===============================
log "🔹 Starting MariaDB client container..."
docker compose up -d

# ===============================
# FETCH AWS RDS CREDENTIALS
# ===============================
log "🔹 Fetching RDS credentials from AWS Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text)

DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')
DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host')

if [[ -z "$DB_USER" || -z "$DB_PASS" || -z "$DB_HOST" ]]; then
    log "❌ Failed to retrieve database credentials"
    exit 1
fi
log "✅ RDS credentials retrieved successfully"

# ===============================
# FUNCTION TO RUN MYSQL COMMANDS INSIDE CONTAINER
# ===============================
run_mysql() {
    local sql="$1"
    docker exec -i mariadb-client mariadb \
        -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" \
        -e "$sql"
}

# ===============================
# CREATE DATABASE
# ===============================
log "🔹 Creating database '$DB_NAME'..."
run_mysql "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# ===============================
# CREATE TABLE
# ===============================
log "🔹 Creating table '$TABLE_NAME'..."
run_mysql "USE $DB_NAME;
CREATE TABLE IF NOT EXISTS $TABLE_NAME (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# ===============================
# INSERT RANDOM SAMPLE DATA
# ===============================
log "🔹 Inserting $ROWS random sample rows..."
for i in $(seq 1 $ROWS); do
    NAME="Employee_$RANDOM"
    ROLE="Role_$((RANDOM % 5 + 1))"
    run_mysql "USE $DB_NAME; INSERT INTO $TABLE_NAME (name, role) VALUES ('$NAME', '$ROLE');"
done
log "✅ Sample data inserted successfully"

# ===============================
# VERIFY TABLE & DATA
# ===============================
log "🔹 Verifying table and data..."
run_mysql "USE $DB_NAME; SHOW TABLES; SELECT * FROM $TABLE_NAME;"

log "🎉 Charlie Café Docker Compose MariaDB setup complete!"
```

### Step 8: Run the Script Again

```
sudo ./connect-rds.sh
```

Now it should pass the “Docker Compose not installed” check and start your MariaDB client container.

#### 💡 Tip: On Amazon Linux 2023, you don’t need the old docker-compose binary. Always use the plugin style (docker compose …).

#### ✅ Key Improvements with Docker Compose

- Containerized MariaDB client → clean, isolated, reproducible

- Reusable run_mysql function → executes all commands inside container

- Randomized table rows → more realistic DevOps lab scenario

- Logging with timestamps → production-style visibility

- Docker Compose keeps client container alive → you can exec additional commands anytime

- RDS Integration → secure credentials via AWS Secrets Manager

### 4️⃣ — Clone Your GitHub Repository

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

### 5️⃣ — Build Docker Image

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

### 6️⃣ — Run Docker Container

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

#### 3️⃣ — Test Container

#### ✅ Open browser:

```
http://EC2_PUBLIC_IP:8080
```

#### ✅ Expected Page:

```
DevOps Lab Connected to RDS Successfully
```

### 7️⃣ — Configure Nginx Reverse Proxy

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

### 8️⃣ — Verification

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


### 9️⃣ Setup CI/CD with GitHub Actions

#### ✅ Platform: GitHub

#### 1️⃣ Create:

```
.github/workflows/deploy.yml
```

#### 2️⃣ Content:

```
name: DevOps Lab CI/CD

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:

    - name: Checkout Code
      uses: actions/checkout@v3

    - name: Setup SSH
      uses: webfactory/ssh-agent@v0.8.1
      with:
        ssh-private-key: ${{ secrets.EC2_SSH_KEY }}

    - name: Copy Files to EC2
      run: |
        scp -o StrictHostKeyChecking=no -r * ec2-user@EC2_PUBLIC_IP:/home/ec2-user/devops-docker-rds-lab

    - name: Deploy on EC2
      run: |
        ssh -o StrictHostKeyChecking=no ec2-user@EC2_PUBLIC_IP "cd devops-docker-rds-lab && sudo ./deploy.sh"
```

#### 3️⃣ Test CI/CD

#### 1️⃣ Edit index.php:

```
echo "<h2>CI/CD Test Success</h2>";
```

#### 2️⃣ Commit:

```
git add .
git commit -m "CI/CD test"
git push origin main
```

#### 3️⃣ Open:

```
GitHub → Actions
```

Workflow runs automatically.

### ✅ FINAL RESULT

Your lab demonstrates:

✅ Amazon Web Services EC2 + Docker

✅ AWS Secrets Manager + RDS

✅ Nginx reverse proxy

✅ Docker containerized PHP app

✅ GitHub CI/CD automation

This is excellent DevOps portfolio project.
----






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


