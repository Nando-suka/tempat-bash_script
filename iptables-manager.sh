#!/bin/bash

# Direktori penyimpanan konfigurasi dan log
CONFIG_DIR="/etc/iptables_manager"
RULES_FILE="$CONFIG_DIR/saved_rules.v4"
LOG_FILE="$CONFIG_DIR/iptables.log"

# Buat direktori jika belum ada
mkdir -p "$CONFIG_DIR"
touch "$LOG_FILE"

# Fungsi untuk logging
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Fungsi tampilkan menu utama
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
    echo "0. Keluar"
    echo "================================="
    echo -n "Pilih opsi: "
}

# Fungsi tampilkan aturan
show_rules() {
    echo -e "\nAturan iptables saat ini:"
    echo "============================"
    iptables -L -v -n --line-numbers
    echo -e "============================\n"
    log_action "Menampilkan aturan iptables"
}

# Fungsi tambah aturan
add_rule() {
    echo -n "Masukkan chain (INPUT/FORWARD/OUTPUT): "
    read chain
    echo -n "Masukkan protocol (tcp/udp/icmp/all): "
    read proto
    echo -n "Masukkan port (kosongkan jika tidak ada): "
    read port
    echo -n "Masukkan alamat IP sumber (kosongkan untuk semua): "
    read source_ip
    echo -n "Masukkan tindakan (ACCEPT/DROP/REJECT): "
    read action
    
    cmd="iptables -A $chain"
    [ -n "$source_ip" ] && cmd+=" -s $source_ip"
    [ "$proto" != "all" ] && cmd+=" -p $proto"
    [ -n "$port" ] && cmd+=" --dport $port"
    cmd+=" -j $action"
    
    eval "$cmd"
    log_action "Menambahkan aturan: $cmd"
    echo "Aturan berhasil ditambahkan!"
}

# Fungsi hapus aturan
delete_rule() {
    show_rules
    echo -n "Masukkan nomor chain (INPUT/FORWARD/OUTPUT): "
    read chain
#!/bin/bash

# Direktori penyimpanan konfigurasi dan log
CONFIG_DIR="/etc/iptables_manager"
RULES_FILE="$CONFIG_DIR/saved_rules.v4"
LOG_FILE="$CONFIG_DIR/iptables.log"

# Buat direktori jika belum ada
mkdir -p "$CONFIG_DIR"
touch "$LOG_FILE"

# Fungsi untuk logging
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Fungsi tampilkan menu utama
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
    echo "0. Keluar"
    echo "================================="
    echo -n "Pilih opsi: "
}

# Fungsi tampilkan aturan
show_rules() {
    echo -e "\nAturan iptables saat ini:"
    echo "============================"
    iptables -L -v -n --line-numbers
    echo -e "============================\n"
    log_action "Menampilkan aturan iptables"
}

# Fungsi tambah aturan
add_rule() {
    echo -n "Masukkan chain (INPUT/FORWARD/OUTPUT): "
    read chain
    echo -n "Masukkan protocol (tcp/udp/icmp/all): "
    read proto
    echo -n "Masukkan port (kosongkan jika tidak ada): "
    read port
    echo -n "Masukkan alamat IP sumber (kosongkan untuk semua): "
    read source_ip
    echo -n "Masukkan tindakan (ACCEPT/DROP/REJECT): "
    read action
    
    cmd="iptables -A $chain"
    [ -n "$source_ip" ] && cmd+=" -s $source_ip"
    [ "$proto" != "all" ] && cmd+=" -p $proto"
    [ -n "$port" ] && cmd+=" --dport $port"
    cmd+=" -j $action"
    
    eval "$cmd"
    log_action "Menambahkan aturan: $cmd"
    echo "Aturan berhasil ditambahkan!"
}

# Fungsi hapus aturan
delete_rule() {
    show_rules
    echo -n "Masukkan nomor chain (INPUT/FORWARD/OUTPUT): "
    read chain
    echo -n "Masukkan nomor aturan yang akan dihapus: "
    read rule_num
    
    iptables -D "$chain" "$rule_num"
    log_action "Menghapus aturan $rule_num dari chain $chain"
    echo "Aturan berhasil dihapus!"
}

# Fungsi blokir IP
block_ip() {
    echo -n "Masukkan alamat IP yang akan diblokir: "
    read ip
    iptables -A INPUT -s "$ip" -j DROP
    log_action "Memblokir IP: $ip"
    echo "IP $ip berhasil diblokir!"
}

# Fungsi izinkan IP
allow_ip() {
    echo -n "Masukkan alamat IP yang akan diizinkan: "
    read ip
    iptables -A INPUT -s "$ip" -j ACCEPT
    log_action "Mengizinkan IP: $ip"
    echo "IP $ip berhasil diizinkan!"
}

# Fungsi blokir port
block_port() {
    echo -n "Masukkan nomor port yang akan diblokir: "
    read port
    iptables -A INPUT -p tcp --dport "$port" -j DROP
    iptables -A INPUT -p udp --dport "$port" -j DROP
    log_action "Memblokir port: $port"
    echo "Port $port berhasil diblokir!"
}

# Fungsi izinkan port
allow_port() {
    echo -n "Masukkan nomor port yang akan diizinkan: "
    read port
    echo -n "Masukkan protocol (tcp/udp): "
    read proto
    iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
    log_action "Mengizinkan port: $port/$proto"
    echo "Port $port/$proto berhasil diizinkan!"
}

# Fungsi simpan aturan
save_rules() {
    iptables-save > "$RULES_FILE"
    log_action "Menyimpan aturan ke $RULES_FILE"
    echo "Aturan berhasil disimpan secara permanen!"
    echo "Untuk memuat saat boot, gunakan perintah:"
    echo "  sudo iptables-restore < $RULES_FILE"
}

# Fungsi pulihkan aturan
restore_rules() {
    [ -f "$RULES_FILE" ] || {
        echo "File aturan tidak ditemukan!"
        return 1
    }
    iptables-restore < "$RULES_FILE"
    log_action "Memulihkan aturan dari $RULES_FILE"
    echo "Aturan berhasil dipulihkan!"
}

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
        0) echo "Keluar..."; exit 0 ;;
        *) echo "Opsi tidak valid!"; sleep 1 ;;
    esac
    echo -n "Tekan Enter untuk melanjutkan..."
    read
done
