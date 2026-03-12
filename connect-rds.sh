#!/bin/bash

# ==========================================================
# CHARLIE CAFÉ RDS MARIADB SETUP SCRIPT
# ==========================================================
# This script installs MariaDB client on Amazon Linux 2023,
# connects to an RDS MySQL/MariaDB instance using AWS Secrets,
# creates a database, a random table, inserts sample data,
# and verifies the creation.
# ==========================================================

# ===============================
# CONFIGURATION
# ===============================

SECRET_ID="CafeDevDBSM"
AWS_REGION="us-east-1"
DB_NAME="cafe_db"
TABLE_NAME="employees"

# ===============================
# INSTALL MARIADB CLIENT
# ===============================

echo "🔹 Installing MariaDB client..."
sudo dnf install -y mariadb105

# Verify installation
echo "🔹 Verifying MariaDB client version..."
mysql --version
if [[ $? -ne 0 ]]; then
  echo "❌ MariaDB client installation failed!"
  exit 1
fi

# ===============================
# FETCH SECRET
# ===============================

echo "🔹 Fetching RDS credentials from Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text)

# ===============================
# PARSE VALUES
# ===============================

DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')
DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host')

# ===============================
# VALIDATION
# ===============================

if [[ -z "$DB_USER" || -z "$DB_PASS" || -z "$DB_HOST" ]]; then
  echo "❌ Failed to retrieve database credentials"
  exit 1
fi

echo "✅ RDS credentials retrieved successfully"

# ===============================
# CONNECT TO MYSQL & CREATE DB
# ===============================

echo "🔹 Connecting to RDS and creating database '$DB_NAME'..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;

# Create a random table with sample data
CREATE TABLE IF NOT EXISTS $TABLE_NAME (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# Insert sample data
INSERT INTO $TABLE_NAME (name, role) VALUES 
('Alice', 'Barista'),
('Bob', 'Cashier'),
('Charlie', 'Manager');

# Verify table creation
SHOW TABLES;
SELECT * FROM $TABLE_NAME;
EOF

if [[ $? -eq 0 ]]; then
  echo "✅ Database, table, and sample data created successfully"
else
  echo "❌ Failed to create database or table"
  exit 1
fi

echo "🎉 Charlie Café MariaDB setup complete!"