#!/bin/bash

# ==========================================================
# CHARLIE CAFÉ DOCKER COMPOSE + MARIADB SETUP SCRIPT
# ==========================================================
# This script:
# 1️⃣ Starts a MariaDB client container via Docker Compose
# 2️⃣ Fetches AWS RDS credentials from Secrets Manager
# 3️⃣ Creates database, table, inserts random data
# 4️⃣ Verifies creation
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
# CHECK DOCKER & DOCKER-COMPOSE
# ===============================
if ! command -v docker &> /dev/null; then
    log "❌ Docker not installed."
    exit 1
fi
if ! command -v docker-compose &> /dev/null; then
    log "❌ Docker Compose not installed."
    exit 1
fi
log "✅ Docker and Docker Compose are installed"

# ===============================
# START DOCKER COMPOSE SERVICE
# ===============================
log "🔹 Starting MariaDB client container..."
docker-compose up -d

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