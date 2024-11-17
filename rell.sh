#!/bin/bash

# Backup sources.list sebelum diubah
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

# Ganti repository menjadi menggunakan mirror kartolo
cat <<EOT | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu focal-security main restricted universe multiverse
EOT

echo "Repository telah diubah ke mirror kartolo."

# Update sistem dan instal paket yang dibutuhkan
sudo apt update
sudo apt upgrade -y
sudo apt install -y vlan isc-dhcp-server net-tools

# Tambahkan modul VLAN
sudo modprobe 8021q

# Konfigurasi interface VLAN
# Misalnya, untuk VLAN 10 pada interface eth1
sudo ip link add link eth1 name eth1.10 type vlan id 10
sudo ip addr add 192.168.A.1/24 dev eth1.10
sudo ip link set up dev eth1.10

# Konfigurasi DHCP Server untuk VLAN 10
cat <<EOT | sudo tee /etc/dhcp/dhcpd.conf
subnet 192.168.12.0 netmask 255.255.255.0 {
    range 192.168.12.100 192.168.12.200;
    option routers 192.168.12.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOT

# Konfigurasi interface DHCP
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="eth1.10"/' /etc/default/isc-dhcp-server

# Restart DHCP server
sudo systemctl restart isc-dhcp-server

# Aktifkan IP forwarding untuk routing
sudo sysctl -w net.ipv4.ip_forward=1

# Tambahkan aturan iptables untuk NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Simpan aturan iptables agar bertahan setelah reboot
sudo apt install -y iptables-persistent
sudo netfilter-persistent save

echo "Konfigurasi jaringan selesai. DHCP, VLAN, dan routing telah diatur."
