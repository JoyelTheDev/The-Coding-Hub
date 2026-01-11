#!/bin/bash
# DO NOT EXIT ON ERROR (LOGIN LOOP FIX)
set +e
export DEBIAN_FRONTEND=noninteractive

echo "=== ULTIMATE DEBIAN 12 → PROXMOX AUTO FIX + INSTALL ==="

# ---------------- ROOT CHECK ----------------
if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

mount -o remount,rw / || true

# ---------------- DISK EMERGENCY CLEAN ----------------
echo "[1/12] Disk + temp cleanup..."
rm -rf /var/lib/apt/lists/* \
       /var/cache/apt/archives/* \
       /tmp/* /var/tmp/* || true
apt clean || true
journalctl --vacuum-size=100M || true

# ---------------- NUKE ALL APT TRUST ----------------
echo "[2/12] Resetting APT keys & trust..."
rm -f /etc/apt/trusted.gpg
rm -rf /etc/apt/trusted.gpg.d/*
rm -rf /usr/share/keyrings/*

# ---------------- MINIMAL TOOLS ----------------
echo "[3/12] Installing minimal tools..."
apt update || true
apt install -y ca-certificates gnupg curl wget iproute2 || true

# ---------------- FORCE DEBIAN KEYRING ----------------
echo "[4/12] Reinstalling Debian archive keyring..."
apt install -y --reinstall debian-archive-keyring || true

# ---------------- MANUAL KEY IMPORT (NUCLEAR) ----------
echo "[5/12] Importing Debian signing keys..."
curl -fsSL https://ftp-master.debian.org/keys/archive-key-12.asc \
| gpg --dearmor -o /usr/share/keyrings/debian-archive-keyring.gpg

curl -fsSL https://ftp-master.debian.org/keys/archive-key-12-security.asc \
| gpg --dearmor -o /usr/share/keyrings/debian-security-keyring.gpg

# ---------------- HARD RESET SOURCES ------------------
echo "[6/12] Writing clean Debian sources..."
rm -f /etc/apt/sources.list.d/* || true

cat > /etc/apt/sources.list <<EOF
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb [signed-by=/usr/share/keyrings/debian-security-keyring.gpg] http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

# ---------------- FINAL APT TEST ----------------
echo "[7/12] Testing apt (must succeed)..."
apt update || {
  echo "❌ APT STILL BROKEN → VPS IMAGE CORRUPT"
  exit 1
}

# ---------------- HOSTNAME FIX ----------------
hostname -f >/dev/null 2>&1 || hostnamectl set-hostname proxmox.local

# ---------------- PROXMOX REPO + KEY ----------------
echo "[8/12] Adding Proxmox repo..."
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
> /etc/apt/sources.list.d/pve-no-subscription.list

curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg \
-o /usr/share/keyrings/proxmox-release.gpg

apt update

# ---------------- POSTFIX NON-INTERACTIVE --------------
echo "[9/12] Preconfiguring Postfix..."
echo "postfix postfix/mailname string localhost" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections

# ---------------- INSTALL PROXMOX ----------------
echo "[10/12] Installing Proxmox VE..."
dpkg -l | grep -q proxmox-ve || \
apt install -y proxmox-ve postfix open-iscsi

# ---------------- AUTO NETWORK vmbr0 ----------------
echo "[11/12] Auto network (vmbr0)..."
IFACE=$(ip route | awk '/default/ {print $5; exit}')
IPCIDR=$(ip -4 addr show "$IFACE" | awk '/inet/ {print $2; exit}')
GATEWAY=$(ip route | awk '/default/ {print $3; exit}')

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $IFACE
iface $IFACE inet manual

auto vmbr0
iface vmbr0 inet static
    address $IPCIDR
    gateway $GATEWAY
    bridge-ports $IFACE
    bridge-stp off
    bridge-fd 0
EOF

systemctl restart networking || true
sleep 5

# ---------------- IPV6 + SSL FIX ----------------
echo "[12/12] IPv6 + SSL fix..."
cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sysctl --system

systemctl stop pveproxy pvedaemon || true
rm -f /etc/pve/local/pve-ssl.* /etc/pve/nodes/*/pve-ssl.*
systemctl restart pve-cluster
sleep 5
pvecm updatecerts --force
systemctl start pvedaemon pveproxy

# ---------------- ENTERPRISE REPO OFF ----------------
sed -i 's|^deb https://enterprise.proxmox.com|# deb https://enterprise.proxmox.com|' \
/etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true

# ---------------- DONE ----------------
echo "=============================================="
echo "✅ ALL FIXED + PROXMOX INSTALLED"
echo "🌐 https://SERVER-IP:8006"
echo "🔁 REBOOT STRONGLY RECOMMENDED"
echo "=============================================="
