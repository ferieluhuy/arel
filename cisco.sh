#!/bin/bash
 
CISCO_IP="192.168.73.131" # Ganti dengan IP perangkat Cisco
CISCO_PORT="30003"

# Konfigurasi Telnet dengan Expect
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
send \"interface vlan 10\r\"
expect \"(config-if)#\"
send \"ip address 192.168.12.1 255.255.255.0\r\"
expect \"(config-if)#\"
send \"no shutdown\r\"
expect \"(config-if)#\"
send \"exit\r\"
send \"end\r\"
expect \"#\"
send \"write memory\r\"
expect \"#\"
send \"exit\r\"
expect eof
"

# Pesan selesai
echo "Konfigurasi Cisco melalui Telnet selesai!"
