#!/bin/bash

CISCO_IP="192.168.73.131"  # IP perangkat Cisco
CISCO_PORT="30003"

# Konfigurasi Cisco: VLAN, Trunking, dan Akses Port DHCP
expect -c "
spawn telnet $CISCO_IP $CISCO_PORT
send \"enable\r\"
expect \"#\"
send \"configure terminal\r\"
expect \"(config)#\"

# Membuat VLAN 10
send \"vlan 10\r\"
expect \"(config-vlan)#\"
send \"name VLAN10\r\"
expect \"(config-vlan)#\"
send \"exit\r\"

# Mengonfigurasi interface trunk (port e0/0)
send \"interface e0/0\r\"  
expect \"(config-if)#\"
send \"switchport trunk encapsulation dot1q\r\"
expect \"(config-if)#\"
send \"switchport mode trunk\"
expect \"(config-if)#\"
send \"exit\r\"

# Mengonfigurasi port akses VLAN 10 (kabel DHCP)
send \"interface e0/1\r\"  
expect \"(config-if)#\"
send \"switchport mode access\r\"
expect \"(config-if)#\"
send \"switchport access vlan 10\r\"
expect \"(config-if)#\"
send \"exit\r\"

# Menyimpan konfigurasi
send \"end\r\"
expect \"#\"
send \"write memory\r\"
expect \"#\"
send \"exit\r\"
expect eof
"

# Pesan selesai
echo "[SUCCESS] VLAN 10 telah ditambahkan, trunking aktif, dan kabel DHCP dipindahkan ke VLAN 10."
