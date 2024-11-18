#!/bin/bash

# IP dan kredensial perangkat Cisco
CISCO_IP="192.168.1.1"      # Ganti dengan IP perangkat Cisco Anda
USERNAME="admin"            # Username SSH Cisco
PASSWORD="cisco123"         # Password SSH Cisco

# Perintah konfigurasi Cisco
read -r -d '' CONFIG_COMMANDS << EOL
conf t
interface vlan 10
ip address 192.168.10.1 255.255.255.0
no shutdown
exit
ip routing
exit
write memory
EOL

# Script untuk mengirim konfigurasi ke Cisco menggunakan SSH
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USERNAME@$192.168.10.1 << EOF
$CONFIG_COMMANDS
EOF

# Pesan sukses
echo "Konfigurasi berhasil diterapkan ke perangkat Cisco!"