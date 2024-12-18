#!/bin/bash

CISCO_IP="192.168.12.10" # Ganti dengan IP perangkat Cisco
CISCO_PORT="30003"
UBUNTU_ROUTE1="192.168.200.0/24"  # Jaringan tujuan pertama
UBUNTU_GATEWAY1="192.168.12.2"    # Gateway pertama
UBUNTU_ROUTE2="192.168.12.0/24"   # Jaringan tujuan kedua (opsional)
UBUNTU_GATEWAY2="192.168.12.1"    # Gateway kedua

# Konfigurasi Telnet dengan Expect untuk Cisco
expect -c "
spawn telnet $CISCO_IP $CISCO_PORT
send \"enable\r\"
expect \"#\"
send \"configure terminal\r\"
expect \"(config)#\"
send \"vlan 10\r\"
expect \"(config-vlan)#\"
send \"name Vlan10\r\"
expect \"(config-vlan)#\"
send \"exit\r\"

# Konfigurasi interface VLAN
send \"interface vlan 10\r\"
expect \"(config-if)#\"
send \"ip address 192.168.12.1 255.255.255.0\r\"
expect \"(config-if)#\"
send \"no shutdown\r\"
expect \"(config-if)#\"
send \"exit\r\"

# Konfigurasi mode trunk pada interface
send \"interface GigabitEthernet0/1\r\"  # Ganti dengan interface yang benar
expect \"(config-if)#\"
send \"switchport mode trunk\r\"
expect \"(config-if)#\"
send \"switchport trunk allowed vlan 10\r\"  # Mengizinkan VLAN 10 di trunk
expect \"(config-if)#\"
send \"exit\r\"

# Menambahkan IP Route di Cisco
expect \"(config)#\"
send \"ip route $UBUNTU_ROUTE1 $UBUNTU_GATEWAY1\r\"
expect \"(config)#\"
send \"ip route $UBUNTU_ROUTE2 $UBUNTU_GATEWAY2\r\"
expect \"(config)#\"
send \"end\r\"
expect \"#\"
send \"write memory\r\"
expect \"#\"
send \"exit\r\"
expect eof
"

# Menambahkan IP Route di Ubuntu
echo "[INFO] Menambahkan IP Route di Ubuntu menggunakan 'via'..."
sudo ip route add $UBUNTU_ROUTE1 via $UBUNTU_GATEWAY1
sudo ip route add $UBUNTU_ROUTE2 via $UBUNTU_GATEWAY2

# Menyimpan IP Route agar permanen di Ubuntu
echo "[INFO] Menyimpan IP Route di Ubuntu agar permanen..."
echo "up ip route add $UBUNTU_ROUTE1 via $UBUNTU_GATEWAY1" | sudo tee -a /etc/network/interfaces > /dev/null
echo "up ip route add $UBUNTU_ROUTE2 via $UBUNTU_GATEWAY2" | sudo tee -a /etc/network/interfaces > /dev/null

# Verifikasi konfigurasi routing
echo "[INFO] Routing aktif saat ini:"
ip route

# Pesan selesai
echo "[SUCCESS] Konfigurasi Cisco dan penambahan IP Route ke Ubuntu selesai!"
