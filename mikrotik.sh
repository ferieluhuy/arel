#!/bin/bash

# Konfigurasi MikroTik
MIKROTIK_IP="192.168.12.2"
USERNAME="admin"
PASSWORD="password"
PORT="22"

# Konfigurasi jaringan yang akan diatur
VLAN_INTERFACE="vlan10"
VLAN_ID="10"
ADDRESS="192.168.12.2/24"
GATEWAY="192.168.12.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Skrip konfigurasi MikroTik
CONFIG_SCRIPT=$(cat <<EOF
/interface vlan
add name=vlan10 vlan-id=10 interface=ether1

/ip address
add address=192.168.10.1/24 interface=vlan10

/ip route
add gateway=192.168.12.1

/ip dns
set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes

/system identity
set name="Router-VLAN10"

/interface print
/ip address print
/ip route print
/ip dns print
EOF
)

# Kirim konfigurasi ke MikroTik via SSH
echo "Mengirim konfigurasi ke MikroTik..."
sshpass -p "$PASSWORD" ssh -p "$PORT" "$USERNAME@$MIKROTIK_IP" "$CONFIG_SCRIPT"

echo "Konfigurasi selesai!"
