#!/bin/bash

# Konfigurasi sistem
CONFIG_DIR="/etc/iptables_manager"
RULES_FILE="$CONFIG_DIR/saved_rules.v4"
BACKUP_DIR="$CONFIG_DIR/backups"
LOG_FILE="$CONFIG_DIR/iptables.log"
WHITELIST_FILE="$CONFIG_DIR/whitelist.txt"
BLOCKLIST_FILE="$CONFIG_DIR/blocklist.txt"

# Inisialisasi direktori
mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
touch "$LOG_FILE" "$WHITELIST_FILE" "$BLOCKLIST_FILE"

# Fungsi logging
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Fungsi buat backup otomatis
auto_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$RULES_FILE" "$BACKUP_DIR/rules_$timestamp.v4"
}

# Tampilkan header
show_header() {
    clear
    echo "==================================================="
    echo "  MANAJEMEN IPTABLES TERKELOLA v2.0"
    echo "  Sistem Terakhir Diperbarui: 12 Agustus 2025"
    echo "==================================================="
}

# Menu utama
show_menu() {
    show_header
    echo "1.  Tampilkan Aturan iptables"
    echo "2.  Tambah Aturan Baru"
    echo "3.  Hapus Aturan"
    echo "4.  Blokir IP"
    echo "5.  Izinkan IP"
    echo "6.  Blokir Port"
    echo "7.  Izinkan Port"
    echo "8.  Simpan Aturan Permanen"
    echo "9.  Pulihkan Aturan"
    echo "10. Tampilkan Log"
    echo "11. Manajemen Blokir Massal"
    echo "12. Manajemen Whitelist"
    echo "13. Aturan Koneksi Terkait (Stateful)"
    echo "14. Anti-DDoS (Rate Limiting)"
    echo "15. Atur Interface Spesifik"
    echo "16. Cek Koneksi Aktif"
    echo "17. Buat Backup"
    echo "18. Restore Backup"
    echo "0.  Keluar"
    echo "==================================================="
    echo -n "Pilih opsi: "
}

# Implementasi fitur baru
# [Fungsi yang sama seperti sebelumnya...]

# 11. Manajemen Blokir Massal
manage_blocklist() {
    show_header
    echo "MANAJEMEN BLOKIR MASSA"
    echo "-----------------------------------"
    echo "1. Blokir IP dari file"
    echo "2. Tambah IP ke blocklist"
    echo "3. Tampilkan daftar blokir"
    echo "4. Kosongkan blocklist"
    echo "-----------------------------------"
    echo -n "Pilihan: "
    read subopt
    
    case $subopt in
        1)
            echo -n "Masukkan path file: "
            read file_path
            if [ -f "$file_path" ]; then
                while IFS= read -r ip; do
                    iptables -A INPUT -s "$ip" -j DROP
                    echo "$ip" >> "$BLOCKLIST_FILE"
                    log_action "IP diblokir dari file: $ip"
                done < "$file_path"
                echo "Semua IP dalam file berhasil diblokir!"
            else
                echo "File tidak ditemukan!"
            fi
            ;;
        2)
            echo -n "Masukkan IP untuk diblokir: "
            read ip
            iptables -A INPUT -s "$ip" -j DROP
            echo "$ip" >> "$BLOCKLIST_FILE"
            log_action "IP ditambahkan ke blocklist: $ip"
            echo "IP berhasil ditambahkan ke blocklist!"
            ;;
        3)
            echo -e "\nDaftar IP Terblokir:"
            cat "$BLOCKLIST_FILE"
            ;;
        4)
            > "$BLOCKLIST_FILE"
            log_action "Blocklist dikosongkan"
            echo "Blocklist berhasil dikosongkan!"
            ;;
        *) echo "Pilihan tidak valid!" ;;
    esac
}

# 12. Manajemen Whitelist
manage_whitelist() {
    show_header
    echo "MANAJEMEN WHITELIST"
    echo "-----------------------------------"
    echo "1. Izinkan IP dari file"
    echo "2. Tambah IP ke whitelist"
    echo "3. Tampilkan whitelist"
    echo "4. Kosongkan whitelist"
    echo "-----------------------------------"
    echo -n "Pilihan: "
    read subopt
    
    case $subopt in
        1)
            echo -n "Masukkan path file: "
            read file_path
            if [ -f "$file_path" ]; then
                while IFS= read -r ip; do
                    iptables -A INPUT -s "$ip" -j ACCEPT
                    echo "$ip" >> "$WHITELIST_FILE"
                    log_action "IP diizinkan dari file: $ip"
                done < "$file_path"
                echo "Semua IP dalam file berhasil diizinkan!"
            else
                echo "File tidak ditemukan!"
            fi
            ;;
        2)
            echo -n "Masukkan IP untuk diizinkan: "
            read ip
            iptables -A INPUT -s "$ip" -j ACCEPT
            echo "$ip" >> "$WHITELIST_FILE"
            log_action "IP ditambahkan ke whitelist: $ip"
            echo "IP berhasil ditambahkan ke whitelist!"
            ;;
        3)
            echo -e "\nDaftar IP Terizinkan:"
            cat "$WHITELIST_FILE"
            ;;
        4)
            > "$WHITELIST_FILE"
            log_action "Whitelist dikosongkan"
            echo "Whitelist berhasil dikosongkan!"
            ;;
        *) echo "Pilihan tidak valid!" ;;
    esac
}

# 13. Aturan Stateful Connection
stateful_rules() {
    show_header
    echo "ATURAN STATEFUL CONNECTION"
    echo "-----------------------------------"
    echo "1. Izinkan koneksi terkait"
    echo "2. Izinkan koneksi established"
    echo "3. Reset stateful rules"
    echo "-----------------------------------"
    echo -n "Pilihan: "
    read subopt
    
    case $subopt in
        1)
            iptables -A INPUT -m conntrack --ctstate RELATED -j ACCEPT
            log_action "Menambahkan aturan RELATED connections"
            echo "Aturan berhasil ditambahkan!"
            ;;
        2)
            iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
            log_action "Menambahkan aturan ESTABLISHED connections"
            echo "Aturan berhasil ditambahkan!"
            ;;
        3)
            iptables -D INPUT -m conntrack --ctstate RELATED -j ACCEPT 2>/dev/null
            iptables -D INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT 2>/dev/null
            log_action "Mereset stateful rules"
            echo "Aturan stateful direset!"
            ;;
        *) echo "Pilihan tidak valid!" ;;
    esac
}

# 14. Basic DDoS Protection
ddos_protection() {
    show_header
    echo "PROTEKSI ANTI-DDoS"
    echo "-----------------------------------"
    echo "1. Aktifkan proteksi SYN Flood"
    echo "2. Aktifkan proteksi Port Scanning"
    echo "3. Atur koneksi per menit"
    echo "-----------------------------------"
    echo -n "Pilihan: "
    read subopt
    
    case $subopt in
        1)
            iptables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT
            log_action "Mengaktifkan SYN Flood protection"
            echo "Proteksi SYN Flood diaktifkan!"
            ;;
        2)
            iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 1/h -j ACCEPT
            iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j ACCEPT
            log_action "Mengaktifkan Port Scan protection"
            echo "Proteksi Port Scanning diaktifkan!"
            ;;
        3)
            echo -n "Masukkan batas koneksi per menit: "
            read limit
            iptables -A INPUT -p tcp -m connlimit --connlimit-above "$limit" -j DROP
            log_action "Mengatur batas koneksi: $limit/menit"
            echo "Batas koneksi diatur ke $limit per menit!"
            ;;
        *) echo "Pilihan tidak valid!" ;;
    esac
}

# 15. Aturan berdasarkan Interface
interface_rules() {
    show_header
    echo -n "Masukkan nama interface (eth0, wlan0, dll): "
    read iface
    echo -n "Masukkan aksi (ACCEPT/DROP): "
    read action
    echo -n "Masukkan port (opsional): "
    read port
    
    cmd="iptables -A INPUT -i $iface"
    [ -n "$port" ] && cmd+=" -p tcp --dport $port"
    cmd+=" -j $action"
    
    eval "$cmd"
    log_action "Menambahkan aturan interface: $cmd"
    echo "Aturan berhasil ditambahkan untuk interface $iface!"
}

# 16. Cek Koneksi Aktif
check_connections() {
    show_header
    echo "KONEKSI AKTIF"
    echo "-----------------------------------"
    echo "1. Tampilkan semua koneksi"
    echo "2. Cek koneksi ke port spesifik"
    echo "-----------------------------------"
    echo -n "Pilihan: "
    read subopt
    
    case $subopt in
        1)
            netstat -tunap
            ;;
        2)
            echo -n "Masukkan nomor port: "
            read port
            netstat -tunap | grep ":$port"
            ;;
        *) echo "Pilihan tidak valid!" ;;
    esac
}

# 17. Buat Backup
create_backup() {
    show_header
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$RULES_FILE" "$BACKUP_DIR/rules_$timestamp.v4"
    log_action "Membuat backup: rules_$timestamp.v4"
    echo "Backup berhasil dibuat: rules_$timestamp.v4"
}

# 18. Restore Backup
restore_backup() {
    show_header
    echo "BACKUP TERSEDIA:"
    ls -l "$BACKUP_DIR"
    echo "-----------------------------------"
    echo -n "Masukkan nama file backup: "
    read backup_file
    
    if [ -f "$BACKUP_DIR/$backup_file" ]; then
        iptables-restore < "$BACKUP_DIR/$backup_file"
        log_action "Memulihkan backup: $backup_file"
        echo "Backup berhasil dipulihkan!"
    else
        echo "File backup tidak ditemukan!"
    fi
}

# [Fungsi-fungsi sebelumnya tetap ada di sini...]

# Main program
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
        11) manage_blocklist ;;
        12) manage_whitelist ;;
        13) stateful_rules ;;
        14) ddos_protection ;;
        15) interface_rules ;;
        16) check_connections ;;
        17) create_backup ;;
        18) restore_backup ;;
        0) echo "Keluar..."; exit 0 ;;
        *) echo "Opsi tidak valid!"; sleep 1 ;;
    esac
    echo -n "Tekan Enter untuk melanjutkan..."
    read
done
