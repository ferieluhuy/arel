#!/usr/bin/expect

# Aktifkan log untuk debug
log_user 1

# Mulai sesi telnet ke MikroTik
spawn telnet 192.168.73.131 30007                  
set timeout 10

# Login otomatis
expect "Mikrotik Login: " { send "admin\r" }
expect "Password: " { send "\r" }

# Tangani prompt lisensi atau permintaan password baru
expect {
    -re "Do you want to see the software license.*" {
        send "n\r"
        exp_continue
    }
    "new password>" {
        send "123\r"
        expect "repeat new password>" { send "123\r" }
    }
}

# Verifikasi apakah login berhasil
expect {
    "Password changed" { puts "Password berhasil diubah." }
    ">" { puts "Login berhasil tanpa perubahan password." }
    timeout { puts "Error: Timeout setelah login."; exit 1 }
}

# Menambahkan IP Address untuk ether2
send "/ip address add address=192.168.200.1/24 interface=ether2\r"
expect ">"

#!/bin/bash

sshpass -p "123" ssh -o StrictHostKeyChecking=no admin@192.168.73.131 << EOF
/ip address add address=192.168.200.1/24 interface=ether2
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade
/ip route add gateway=192.168.12.1
/ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.100
/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool disabled=no
/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8,8.8.4.4
/ip service enable ssh
quit
EOF
