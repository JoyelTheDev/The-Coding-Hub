#!/bin/bash
# ==================================================
# PTERODACTYL PANEL AUTO INSTALLER
# Clean UI • One Page • Production Ready
# ==================================================

# ---------------- UI THEME ----------------
C_RESET="\e[0m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_PURPLE="\e[1;35m"
C_CYAN="\e[1;36m"
C_WHITE="\e[1;37m"
C_GRAY="\e[1;90m"

line(){ echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }
step(){ echo -e "${C_BLUE}➜ $1${C_RESET}"; }
ok(){ echo -e "${C_GREEN}✔ $1${C_RESET}"; }
warn(){ echo -e "${C_YELLOW}⚠ $1${C_RESET}"; }

banner(){
clear
echo -e "${C_CYAN}"
cat << "EOF"
 ███████████                                                            █████                      
░░███░░░░░███                                                          ░░███                       
 ░███    ░███  ██████   █████ ████ █████████████    ██████  ████████   ███████    ██████  ████████ 
 ░██████████  ░░░░░███ ░░███ ░███ ░░███░░███░░███  ███░░███░░███░░███ ░░░███░    ███░░███░░███░░███
 ░███░░░░░░    ███████  ░███ ░███  ░███ ░███ ░███ ░███████  ░███ ░███   ░███    ░███████  ░███ ░░░ 
 ░███         ███░░███  ░███ ░███  ░███ ░███ ░███ ░███░░░   ░███ ░███   ░███ ███░███░░░   ░███     
 █████       ░░████████ ░░███████  █████░███ █████░░██████  ████ █████  ░░█████ ░░██████  █████    
░░░░░         ░░░░░░░░   ░░░░░███ ░░░░░ ░░░ ░░░░░  ░░░░░░  ░░░░ ░░░░░    ░░░░░   ░░░░░░  ░░░░░     
                         ███ ░███                                                                  
                        ░░██████                                                                   
                         ░░░░░░                                                                    
        Payment PANEL INSTALLER
EOF
echo -e "${C_RESET}"
line
echo -e "${C_GREEN}⚡ Fast • Stable • Production Ready${C_RESET}"
echo -e "${C_PURPLE}🧠 The Coding Hub — 2026 Installer${C_RESET}"
echo -e "${CYAN}${BOLD}Domain Configuration:${NC}"
echo -e "${WHITE}Please enter your domain name for Paymenter${NC}"
line
}

read -rp "$(echo -e "${YELLOW}➤ Enter domain for Paymenter (e.g. paymenter.example.com): ${NC}")" DOMAIN

if [ -z "$DOMAIN" ]; then
  print_error "No domain entered. Exiting."
  exit 1
fi

echo -e "${GREEN}✓ Domain set to: ${WHITE}${DOMAIN}${NC}"
echo -e ""

# --- Dependencies ---
apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release
# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "ubuntu" ]]; then
    echo "✅ Detected Ubuntu. Adding PPA for PHP..."
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    echo "✅ Detected Debian. Skipping PPA and adding PHP repo manually..."
    # Add SURY PHP repo for Debian
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# Add Redis GPG key and repo
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
apt update
# --- Install PHP + extensions ---
apt -y install php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} mariadb-server nginx tar unzip git redis-server
apt install -y php8.3 php8.3-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server
apt purge -y apache2* || true && apt autoremove -y && rm -rf /etc/apache2 /var/www/html /var/log/apache2
# Start installation
print_header
systemctl start mariadb
#======================================================================================================================
mkdir /var/www/paymenter
cd /var/www/paymenter
curl -Lo paymenter.tar.gz https://github.com/paymenter/paymenter/releases/latest/download/paymenter.tar.gz
tar -xzvf paymenter.tar.gz
chmod -R 755 storage/* bootstrap/cache/
DB_NAME="paymenter"
DB_USER="paymenteruser"
DB_PASS="yourPassword" 
mysql -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mysql -e "CREATE DATABASE ${DB_NAME};"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"
print_success "Database '${DB_NAME}' created with user '${DB_USER}'"
print_status "Configuring environment variables..."
cp -n .env.example .env
# Replace common keys (only if patterns exist)
sed -i "s|^APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env || true
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env || true
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env || true
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env || true
print_success "Environment configuration completed"
php artisan key:generate --force
php artisan storage:link
php artisan migrate --force --seed
php artisan db:seed --class=CustomPropertySeeder
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/paymenter/artisan schedule:run >> /dev/null 2>&1") | crontab -
mkdir -p /etc/certs/paymenter
cd /etc/certs/paymenter
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem

tee /etc/nginx/sites-available/paymenter.conf > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/paymenter/public;
    index index.php index.html;

    charset utf-8;

    ssl_certificate /etc/certs/paymenter/fullchain.pem;
    ssl_certificate_key /etc/certs/paymenter/privkey.pem;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ \.php$ {
        return 404;
    }

    client_max_body_size 100m;
    sendfile off;
}
EOF

sudo ln -s /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/ || true
sudo rm /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
chown -R www-data:www-data /var/www/paymenter/*
ok "Nginx online"
# --- Queue Worker ---
tee /etc/systemd/system/paymenter.service > /dev/null << 'EOF'
[Unit]
Description=Paymenter Queue Worker

[Service]
# On some systems the user and group might be different.
# Some systems use `apache` or `nginx` as the user and group.
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/paymenter/artisan queue:work
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable --now paymenter.service
sudo systemctl enable --now redis-server
ok "Queue running"
clear
step "Create admin user"
cd /var/www/paymenter
php artisan app:init
php artisan app:user:create
clear
# ---------------- DONE ----------------
line
echo -e "${C_GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY${C_RESET}"
line
echo -e "${C_CYAN}🌐 Panel URL    : ${C_WHITE}https://${DOMAIN}${C_RESET}"
echo -e "${C_CYAN}🗄 DB User      : ${C_WHITE}${DB_USER}${C_RESET}"
echo -e "${C_CYAN}🔑 DB Password  : ${C_WHITE}${DB_PASS}${C_RESET}"
line
echo -e "${C_PURPLE}🚀 Panel live. Control the servers.${C_RESET}"
line





