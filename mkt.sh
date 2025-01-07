#!/bin/bash

# Informasi Telnet
MIKROTIK_IP="192.168.73.131" # IP Mikrotik
TELNET_PORT="30007"          # Port Telnet Mikrotik

# Konfigurasi Telnet dengan Expect
expect -c "
spawn telnet $MIKROTIK_IP $TELNET_PORT
expect \">\"

#!/usr/bin/expect

# Mulai sesi telnet ke MikroTik
spawn telnet 192.168.234.132 30016
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

# Verifikasi apakah password berhasil diubah
expect {
    "Password changed" {
        puts "Password berhasil diubah."
    }
    "Try again, error: New passwords do not match!" {
        puts "Error: Password tidak cocok. Ulangi pengisian password."
        send "123\r"
        expect "repeat new password>" { send "123\r" }
        expect "Password changed" { puts "Password berhasil diubah." }
    }
    ">" {
        puts "Login berhasil tanpa perubahan password."
    }
    timeout {
        puts "Error: Timeout setelah login."
        exit 1
    }
}

# Konfigurasi DHCP Server
send \"ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.254\r\"
expect \">\"
send \"ip dhcp-server add name=dhcp1 interface=vlan10 address-pool=dhcp_pool lease-time=10m disabled=no\r\"
expect \">\"
send \"ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8\r\"
expect \">\"
    

# Keluar dari Telnet
send \"quit\r\"
expect eof
"

# Pesan selesai
echo "Konfigurasi Mikrotik melalui Telnet selesai!"
