#!/usr/bin/env bash
set -euo pipefail

DOC_ROOT="/var/www/html"

echo "[WEB] Provision (ultra simplifié)"

sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx git mysql-client-core-8.0

sudo chown -R www-data:www-data "$DOC_ROOT" || true

# Minimal Nginx (use default site but point root if needed)
DEFAULT_SITE="/etc/nginx/sites-available/default"
if grep -q "root /var/www/html" "$DEFAULT_SITE"; then
  : # already fine
else
  sudo sed -i 's#root /var/www/html;#root /var/www/html;#' "$DEFAULT_SITE" || true
fi

if [ ! -f "$DOC_ROOT/index.html" ]; then
  echo "[WEB] Creating placeholder index.html"
  sudo bash -c "echo '<h1>Site placeholder</h1>' > $DOC_ROOT/index.html"
  sudo chown www-data:www-data "$DOC_ROOT/index.html"
fi

sudo systemctl enable nginx
sudo systemctl restart nginx

echo "[WEB] Done"
