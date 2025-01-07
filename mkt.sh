#!/usr/bin/expect

# Mulai sesi telnet ke MikroTik
spawn telnet 192.168.73.131 30016
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

# Pastikan berada di prompt MikroTik sebelum melanjutkan
expect ">" { puts "Konfigurasi MikroTik dimulai." }

# Menambahkan IP Address untuk ether2
send "/ip address add address=192.168.200.1/24 interface=ether2\r"
expect ">" 

# Menambahkan NAT Masquerade
send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r"
expect ">"

# Menambahkan Rute Default (Internet Gateway)
send "/ip route add gateway=192.168.12.1\r"
expect ">"

# Menambahkan pool DHCP
send "/ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.100\r"
expect ">"

# Menambahkan konfigurasi DHCP server
send "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool disabled=no\r"
expect ">"

# Menambahkan konfigurasi jaringan DHCP
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8,8.8.4.4\r"
expect ">"

# Keluar dari MikroTik
send "quit\r"
expect eof
