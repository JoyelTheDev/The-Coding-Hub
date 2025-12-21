CONFIG_FILE="/etc/pterodactyl/config.yml"

sed -i 's/host:.*/host: 0.0.0.0/' $CONFIG_FILE
sed -i 's/port:.*/port: 8080/' $CONFIG_FILE

sed -i 's/cert:.*/cert: /etc/certs/wing/fullchain.pem/' $CONFIG_FILE
sed -i 's/key:.*/key: /etc/certs/wing/privkey.pem/' $CONFIG_FILE

# ===== Restart Wings =====
systemctl restart wings

echo -e "${GREEN}
✅ Wings config applied successfully
- Host : 0.0.0.0
- Port : 8080
- SSL  : Enabled
${NC}"
