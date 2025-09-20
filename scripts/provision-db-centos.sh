#!/usr/bin/env bash
set -euo pipefail

ROOT_PASSWORD="RootPass123!"
DEV_USER="devuser"
DEV_PASS="devpass"

echo "[DB] Provision"

sudo dnf install -y mysql-server || sudo dnf install -y mysql-community-server
sudo systemctl enable mysqld
sudo systemctl start mysqld

# Open firewall for MySQL if firewalld is running
if systemctl is-active --quiet firewalld 2>/dev/null; then
  echo "[DB] Opening port 3306/tcp in firewalld"
  sudo firewall-cmd --permanent --add-service=mysql || true
  sudo firewall-cmd --permanent --add-port=3306/tcp || true
  sudo firewall-cmd --reload || true
fi

# Ensure MySQL listens on all interfaces for private network access
if ! grep -q '^bind-address' /etc/my.cnf && ! grep -q '^bind-address' /etc/my.cnf.d/* 2>/dev/null; then
  echo '[mysqld]' | sudo tee -a /etc/my.cnf >/dev/null
  echo 'bind-address=0.0.0.0' | sudo tee -a /etc/my.cnf >/dev/null
else
  sudo sed -i 's/^bind-address.*/bind-address=0.0.0.0/' /etc/my.cnf || true
  sudo sed -i 's/^bind-address.*/bind-address=0.0.0.0/' /etc/my.cnf.d/* 2>/dev/null || true
fi
sudo systemctl restart mysqld

# Set root password on first run
if mysql -u root -e 'SELECT 1' >/dev/null 2>&1; then
  echo "[DB] Root has no password, setting password..."
  mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';"
  mysql -u root -p"$ROOT_PASSWORD" -e "UNINSTALL COMPONENT 'file://component_validate_password';" || true
else
  # Check if temporary password exists
  if sudo test -f /var/log/mysqld.log && sudo grep -q 'temporary password' /var/log/mysqld.log; then
    echo "[DB] Using temporary password..."
    TEMP_PASS=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -1)
    mysql --connect-expired-password -u root -p"$TEMP_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';"
    mysql -u root -p"$ROOT_PASSWORD" -e "UNINSTALL COMPONENT 'file://component_validate_password';" || true
  else
    echo "[DB] Password already set or cannot determine temporary password"
  fi
fi

# Create database and run setup scripts
mysql -u root -p"$ROOT_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS demo_db;
USE demo_db;
SQL

mysql -u root -p"$ROOT_PASSWORD" demo_db < /vagrant/database/create-table.sql || true
mysql -u root -p"$ROOT_PASSWORD" demo_db < /vagrant/database/insert-demo-data.sql || true

# Create development users for both local and remote access
mysql -u root -p"$ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS '$DEV_USER'@'localhost' IDENTIFIED BY '$DEV_PASS';
CREATE USER IF NOT EXISTS '$DEV_USER'@'%' IDENTIFIED BY '$DEV_PASS';
GRANT ALL PRIVILEGES ON demo_db.* TO '$DEV_USER'@'localhost';
GRANT ALL PRIVILEGES ON demo_db.* TO '$DEV_USER'@'%';
FLUSH PRIVILEGES;
SQL

echo "[DB] Done"
