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

# File Netplan yang akan diubah
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"

# Backup file Netplan lama (jika ada)
if [ -f "$NETPLAN_FILE" ]; then
    echo "Membuat cadangan file Netplan lama..."
    cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"
fi

# Buat konfigurasi baru untuk Netplan
echo "Membuat konfigurasi baru untuk Netplan..."
cat << EOF > "$NETPLAN_FILE"
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes
    eth1:
      dhcp4: no
  vlans:
    eth1.10:
      id: 10
      link: eth1
      addresses:
        - 192.168.12.1/24
EOF

# Terapkan konfigurasi Netplan
echo "Menerapkan konfigurasi Netplan..."
netplan apply

# Verifikasi hasil konfigurasi
echo "Konfigurasi selesai. Berikut detail jaringan Anda:"
ip addr
ip route


# Konfigurasi interface VLAN
# Misalnya, untuk VLAN 10 pada interface eth1
sudo ip link add link eth1 name eth1.10 type vlan id 10
sudo ip addr add 192.168.A.1/24 dev eth1.10
sudo ip link set up dev eth1.10

# Konfigurasi DHCP Server untuk VLAN 10
cat <<EOT | sudo tee /etc/dhcp/dhcpd.conf
A slightly different configuration for an internal subnet.
 subnet 10.5.5.0 netmask 255.255.255.224 (
 range 10.5.5.26 10.5.5.30;
 option domain-name-servers ns1.internal.example.org;
  option domain-name "internal.example.org";
 option subnet-mask 255.255.255.224;
 option routers 10.5.5.1;
 option broadcast-address 10.5.5.31;
 default-lease-time 600;
 max-lease-time 7200;

host fantasia {
  hardware ethernet  ;
  fixed-address fantasia ;
} 
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
