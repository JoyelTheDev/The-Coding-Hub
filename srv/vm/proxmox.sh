#!/bin/bash
set -e

echo "=== Proxmox VE Auto Install (Debian 12) ==="

# 1. Basic tools
echo "[1/7] Installing required tools..."
apt update && apt upgrade -y
apt install -y gnupg ca-certificates wget curl lsb-release

# 2. Set hostname (if empty)
if [ -z "$(hostname -f 2>/dev/null)" ]; then
  echo "proxmox.local" > /etc/hostname
  hostnamectl set-hostname proxmox.local
fi

# 3. Add Proxmox repository
echo "[2/7] Adding Proxmox repository..."
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
> /etc/apt/sources.list.d/pve.list

# 4. Add Proxmox GPG key
echo "[3/7] Adding Proxmox GPG key..."
wget -q https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg
gpg --dearmor proxmox-release-bookworm.gpg
mv proxmox-release-bookworm.gpg.gpg /etc/apt/trusted.gpg.d/proxmox.gpg
rm -f proxmox-release-bookworm.gpg

# 5. Preseed Postfix (NO INTERACTIVE PROMPT)
echo "[4/7] Preconfiguring Postfix..."
echo "postfix postfix/mailname string localhost" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections

# 6. Update & install Proxmox
echo "[5/7] Installing Proxmox VE..."
apt update
apt install -y proxmox-ve postfix open-iscsi

# 7. Cleanup Debian kernel (recommended)sysctl -w net.ipv6.conf.all.disable_ipv6=1ip a | grep inet6

sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

echo "[6/7] Cleaning up default Debian kernel..."
apt remove -y linux-image-amd64 linux-image-cloud-amd64 || true
update-grub

echo "[7/7] Installation complete!"
echo "Rebooting in 5 seconds..."
sleep 5
sed -i 's|^deb https://enterprise.proxmox.com|# deb https://enterprise.proxmox.com|' /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true
apt update

systemctl stop pveproxy pvedaemon
systemctl restart pve-cluster
sleep 5
pvecm updatecerts --force
systemctl start pvedaemon pveproxy


echo "=== Proxmox SSL + IPv6 Fix Script (Debian 12) ==="

echo "[1/6] Disabling IPv6 temporarily..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

echo "[2/6] Stopping Proxmox services..."
systemctl stop pveproxy pvedaemon || true

echo "[3/6] Cleaning broken SSL certificates..."
rm -f /etc/pve/local/pve-ssl.*
rm -f /etc/pve/nodes/*/pve-ssl.*

echo "[4/6] Restarting cluster filesystem..."
systemctl restart pve-cluster
sleep 5

echo "[5/6] Regenerating Proxmox certificates..."
pvecm updatecerts --force

echo "[6/6] Starting Proxmox services..."
systemctl start pvedaemon pveproxy

echo "=============================================="
echo "DONE ✅"
echo "Now open: https://SERVER-IP:8006"
echo "If browser warns about SSL → Advanced → Proceed"
echo "=============================================="

reboot

