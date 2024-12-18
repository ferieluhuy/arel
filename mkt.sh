#!/bin/bash

# Membersihkan layar
clear

# Teks ASCII Art
echo "███████ ███████ ██████  ██ ██      "
echo "██      ██      ██   ██ ██ ██      "
echo "█████   █████   ██████  ██ ██      "
echo "██      ██      ██   ██ ██ ██      "
echo "██      ███████ ██   ██ ██ ███████ "
echo ""

# Informasi Telnet
MIKROTIK_IP="192.168.73.131" # IP Mikrotik
TELNET_PORT="30007"          # Port Telnet Mikrotik

# Konfigurasi Telnet dengan Expect
expect -c "
spawn telnet $MIKROTIK_IP $TELNET_PORT
expect \">\"

# Masuk ke mode konfigurasi
send \"system identity set name=Mikrotik-Test\r\"
expect \">\"

# Konfigurasi Interface
send \"interface vlan add name=vlan10 vlan-id=10 interface=ether1\r\"
expect \">\"
send \"ip address add address=192.168.200.1/24 interface=vlan10\r\"
expect \">\"

# Aktifkan NAT (Masquerade)
send \"ip firewall nat add chain=srcnat action=masquerade out-interface=ether1\r\"
expect \">\"

# Konfigurasi DHCP Server
send \"ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.254\r\"
expect \">\"
send \"ip dhcp-server add name=dhcp1 interface=vlan10 address-pool=dhcp_pool lease-time=10m disabled=no\r\"
expect \">\"
send \"ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8\r\"
expect \">\"

# Simpan konfigurasi
send \"system script add name=SaveConfig policy=ftp,read,write,policy,test,password,sniff,sensitive source='system backup save name=config_backup'\r\"
expect \">\"
send \"system script run SaveConfig\r\"
expect \">\"

# Keluar dari Telnet
send \"quit\r\"
expect eof
"

# Pesan selesai
echo "Konfigurasi Mikrotik melalui Telnet selesai!"
