#!/bin/bash

# ===============================
# CONFIGURATION
# ===============================

# Secret Name or ARN
SECRET_ID="CafeDevDBSM"
AWS_REGION="us-east-1"

# ===============================
# FETCH SECRET
# ===============================

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

# ===============================
# CONNECT TO MYSQL (NO DB NAME)
# ===============================

echo "✅ Connecting to RDS MySQL (no database selected)..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS"