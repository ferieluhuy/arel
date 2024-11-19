#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Log file
LOG_FILE="/var/log/setup-script.log"

echo -e "${GREEN}Memulai konfigurasi Ubuntu Server${NC}" | tee -a $LOG_FILE

# 1. Mengganti repository menjadi repository lokal Kartolo
echo -e "${GREEN}Mengganti repository ke Kartolo${NC}" | tee -a $LOG_FILE
if ! cat <<EOF > /etc/apt/sources.list; then
  echo -e "${RED}Gagal mengganti repository. Periksa izin akses.${NC}" | tee -a $LOG_FILE
  exit 1
fi
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe
EOF

apt update &> /dev/null
echo -e "${GREEN}Berhasil mengganti repository dan mengupdate sistem${NC}" | tee -a $LOG_FILE

# 2. Install DHCP Server dan iptables-persistent
echo -e "${GREEN}Menginstall DHCP Server dan iptables-persistent${NC}" | tee -a $LOG_FILE
if ! apt install -y isc-dhcp-server iptables iptables-persistent &> /dev/null; then
  echo -e "${RED}Gagal menginstall DHCP Server atau iptables-persistent.${NC}" | tee -a $LOG_FILE
  exit 1
fi
echo -e "${GREEN}Berhasil menginstall DHCP Server dan iptables-persistent${NC}" | tee -a $LOG_FILE

# 3. Konfigurasi Netplan untuk VLAN 10
echo -e "${GREEN}Mengonfigurasi jaringan dengan VLAN 10${NC}" | tee -a $LOG_FILE
cat <<EOT > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes   # Terhubung ke Internet
    eth1:
      dhcp4: no    # Terhubung ke Mikrotik / Switch
  vlans:
    eth1.10:
      id: 10
      link: eth1
      addresses:
        - 192.168.12.1/24
EOT

if ! netplan apply 2>/dev/null; then
  echo -e "${RED}Gagal menerapkan konfigurasi Netplan. Periksa file konfigurasi.${NC}" | tee -a $LOG_FILE
  exit 1
fi
echo -e "${GREEN}Berhasil menerapkan konfigurasi Netplan${NC}" | tee -a $LOG_FILE

# 4. Konfigurasi DHCP Server
echo -e "${GREEN}Mengonfigurasi DHCP Server${NC}" | tee -a $LOG_FILE
cat <<EOF > /etc/dhcp/dhcpd.conf
# Konfigurasi subnet untuk VLAN 10
subnet 192.168.12.0 netmask 255.255.255.0 {
    range 192.168.12.2 192.168.12.254;
    option domain-name-servers 8.8.8.8;
    option subnet-mask 255.255.255.0;
    option routers 192.168.12.1;
    option broadcast-address 192.168.12.255;
    default-lease-time 600;
    max-lease-time 7200;
}

# Konfigurasi IP statis untuk perangkat tertentu
host fantasia {
    hardware ethernet 00:50:79:66:68:0f;
    fixed-address 192.168.12.10;
}
EOF

if ! dhcpd -t -cf /etc/dhcp/dhcpd.conf; then
  echo -e "${RED}Konfigurasi DHCP Server memiliki kesalahan. Periksa file dhcpd.conf.${NC}" | tee -a $LOG_FILE
  exit 1
fi

echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server
if ! systemctl restart isc-dhcp-server; then
  echo -e "${RED}Gagal me-restart DHCP Server. Periksa status layanan.${NC}" | tee -a $LOG_FILE
  exit 1
fi
echo -e "${GREEN}Berhasil mengkonfigurasi dan me-restart DHCP Server${NC}" | tee -a $LOG_FILE

# 5. Aktifkan IP Forwarding
echo -e "${GREEN}Mengaktifkan IP Forwarding${NC}" | tee -a $LOG_FILE
if ! sysctl -w net.ipv4.ip_forward=1 &> /dev/null; then
  echo -e "${RED}Gagal mengaktifkan IP Forwarding.${NC}" | tee -a $LOG_FILE
  exit 1
fi
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo -e "${GREEN}Berhasil mengaktifkan IP Forwarding${NC}" | tee -a $LOG_FILE

# 6. Konfigurasi NAT dengan iptables
echo -e "${GREEN}Mengonfigurasi iptables untuk NAT${NC}" | tee -a $LOG_FILE
if ! iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; then
  echo -e "${RED}Gagal menambahkan aturan iptables NAT.${NC}" | tee -a $LOG_FILE
  exit 1
fi
iptables -A FORWARD -i eth0 -o eth1.10 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1.10 -o eth0 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
echo -e "${GREEN}Berhasil menyimpan aturan iptables${NC}" | tee -a $LOG_FILE

# 7. Restart layanan terkait
echo -e "${GREEN}Me-restart layanan jaringan dan DHCP server${NC}" | tee -a $LOG_FILE
systemctl restart isc-dhcp-server
systemctl restart systemd-networkd
echo -e "${GREEN}Berhasil menyelesaikan konfigurasi${NC}" | tee -a $LOG_FILE