#!/bin/bash

# ... [Bagian awal script tetap sama] ...

# Menu utama (tambahkan opsi 19)
show_menu() {
    clear
    echo "================================="
    echo "  MANAJEMEN IPTABLES TERKELOLA"
    echo "================================="
    echo "1. Tampilkan Aturan iptables"
    echo "2. Tambah Aturan Baru"
    echo "3. Hapus Aturan"
    echo "4. Blokir IP"
    echo "5. Izinkan IP"
    echo "6. Blokir Port"
    echo "7. Izinkan Port"
    echo "8. Simpan Aturan Permanen"
    echo "9. Pulihkan Aturan Terakhir"
    echo "10. Tampilkan Log"
    echo "19. Rate Limiting (Anti DDoS)"  # Fitur baru
    echo "0. Keluar"
    echo "================================="
    echo -n "Pilih opsi: "
}

# ... [Fungsi-fungsi sebelumnya tetap sama] ...

# 19. Fitur Rate Limiting (Baru)
rate_limiting() {
    echo -e "\n=== RATE LIMITING (ANTI DDoS) ==="
    echo "1. Aktifkan rate limiting untuk SSH"
    echo "2. Aktifkan rate limiting untuk HTTP/HTTPS"
    echo "3. Aktifkan rate limiting kustom"
    echo "4. Nonaktifkan rate limiting"
    echo "5. Tampilkan aturan rate limiting"
    echo "=================================="
    echo -n "Pilih opsi: "
    read subopt
    
    case $subopt in
        1)
            # Rate limiting untuk SSH (port 22)
            iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
            iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
            log_action "Rate limiting diaktifkan untuk SSH (maks 3 koneksi per menit)"
            echo "Berhasil! Maksimal 3 koneksi baru per menit ke SSH"
            ;;
        2)
            # Rate limiting untuk HTTP/HTTPS
            iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --set --name HTTP
            iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 10 --hitcount 20 --name HTTP -j DROP
            iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --set --name HTTPS
            iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 10 --hitcount 20 --name HTTPS -j DROP
            log_action "Rate limiting diaktifkan untuk HTTP/HTTPS (maks 20 koneksi per 10 detik)"
            echo "Berhasil! Maksimal 20 koneksi baru per 10 detik ke HTTP/HTTPS"
            ;;
        3)
            echo -n "Masukkan port: "
            read port
            echo -n "Batas koneksi per menit: "
            read limit
            echo -n "Protocol (tcp/udp): "
            read proto
            
            # Buat chain khusus
            iptables -N RATE_LIMIT_$port 2>/dev/null
            
            # Aturan rate limiting
            iptables -A RATE_LIMIT_$port -m recent --set
            iptables -A RATE_LIMIT_$port -m recent --update --seconds 60 --hitcount $((limit+1)) -j DROP
            iptables -A RATE_LIMIT_$port -j ACCEPT
            
            # Terapkan ke input
            iptables -A INPUT -p $proto --dport $port -m state --state NEW -j RATE_LIMIT_$port
            
            log_action "Rate limiting kustom diaktifkan: port $port, $limit/menit"
            echo "Berhasil! Maksimal $limit koneksi baru per menit ke port $port"
            ;;
        4)
            # Nonaktifkan semua rate limiting
            iptables -D INPUT -p tcp --dport 22 -m state --state NEW -m recent --set 2>/dev/null
            iptables -D INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP 2>/dev/null
            
            # Hapus chain kustom
            for chain in $(iptables -L | grep RATE_LIMIT_ | awk '{print $2}'); do
                iptables -F $chain
                iptables -X $chain
            done
            
            log_action "Semua aturan rate limiting dinonaktifkan"
            echo "Rate limiting dinonaktifkan!"
            ;;
        5)
            echo -e "\nAturan Rate Limiting Aktif:"
            echo "============================="
            iptables -L INPUT -v -n | grep -E 'REJECT|DROP|RATE_LIMIT'
            iptables -L | grep -A2 'Chain RATE_LIMIT_'
            echo "============================="
            ;;
        *) echo "Opsi tidak valid!" ;;
    esac
}

# Main program (tambahkan case 19)
while true; do
    show_menu
    read choice
    case $choice in
        1) show_rules ;;
        2) add_rule ;;
        3) delete_rule ;;
        4) block_ip ;;
        5) allow_ip ;;
        6) block_port ;;
        7) allow_port ;;
        8) save_rules ;;
        9) restore_rules ;;
        10) less "$LOG_FILE" ;;
        19) rate_limiting ;;  # Fitur baru
        0) echo "Keluar..."; exit 0 ;;
        *) echo "Opsi tidak valid!"; sleep 1 ;;
    esac
    echo -n "Tekan Enter untuk melanjutkan..."
    read
done
