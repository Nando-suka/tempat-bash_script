#!/bin/bash

# Log Cleaner Script v1.0
# Script untuk membersihkan log files lama dan mengompres yang masih diperlukan

# Konfigurasi default
CONFIG_FILE="/etc/logcleaner.conf"
DEFAULT_LOG_DIRS=("/var/log" "$HOME/.local/share/logs" "/tmp")
DEFAULT_DAYS_TO_KEEP=7
DEFAULT_DAYS_TO_COMPRESS=3
DRY_RUN=false
VERBOSE=false

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fungsi untuk logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Fungsi untuk menampilkan bantuan
show_help() {
    cat << EOF
Log Cleaner Script v1.0

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -d, --days DAYS         Jumlah hari untuk menyimpan log (default: 7)
    -c, --compress DAYS     Jumlah hari sebelum compress (default: 3)
    -p, --path PATH         Path direktori log tambahan
    -n, --dry-run          Jalankan tanpa melakukan perubahan (preview only)
    -v, --verbose          Output detail
    -h, --help             Tampilkan bantuan ini

EXAMPLES:
    $0                      # Jalankan dengan setting default
    $0 -d 14 -c 7          # Simpan 14 hari, compress setelah 7 hari
    $0 -n -v               # Preview mode dengan output detail
    $0 -p /opt/myapp/logs  # Tambah direktori custom

CONFIG FILE:
    File konfigurasi: $CONFIG_FILE
    Format:
        LOG_DIRS="/var/log /home/user/logs"
        DAYS_TO_KEEP=7
        DAYS_TO_COMPRESS=3
        EXCLUDE_PATTERNS="*.pid *.lock"
EOF
}

# Load konfigurasi dari file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "Loading config from $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
    
    # Set default values jika tidak ada di config
    DAYS_TO_KEEP=${DAYS_TO_KEEP:-$DEFAULT_DAYS_TO_KEEP}
    DAYS_TO_COMPRESS=${DAYS_TO_COMPRESS:-$DEFAULT_DAYS_TO_COMPRESS}
    
    if [[ -n "$LOG_DIRS" ]]; then
        IFS=' ' read -ra LOG_DIRECTORIES <<< "$LOG_DIRS"
    else
        LOG_DIRECTORIES=("${DEFAULT_LOG_DIRS[@]}")
    fi
}

# Fungsi untuk mendapatkan ukuran file dalam format human readable
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        du -h "$file" | cut -f1
    else
        echo "0"
    fi
}

# Fungsi untuk compress log files
compress_logs() {
    local dir="$1"
    local compress_days="$2"
    local total_compressed=0
    local total_size_before=0
    local total_size_after=0
    
    log "Compressing logs older than $compress_days days in $dir"
    
    # Cari file log yang perlu dikompres
    while IFS= read -r -d '' file; do
        if [[ ! "$file" =~ \.(gz|bz2|xz)$ ]] && [[ -f "$file" ]]; then
            size_before=$(stat -c%s "$file" 2>/dev/null || echo 0)
            total_size_before=$((total_size_before + size_before))
            
            if [[ "$VERBOSE" = true ]]; then
                log "  Compressing: $file ($(get_file_size "$file"))"
            fi
            
            if [[ "$DRY_RUN" = false ]]; then
                gzip "$file" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    ((total_compressed++))
                    size_after=$(stat -c%s "${file}.gz" 2>/dev/null || echo 0)
                    total_size_after=$((total_size_after + size_after))
                fi
            else
                ((total_compressed++))
            fi
        fi
    done < <(find "$dir" -type f -name "*.log" -o -name "*.out" -o -name "*.err" | \
             xargs -0 -I {} find {} -mtime +$compress_days -print0 2>/dev/null)
    
    if [[ $total_compressed -gt 0 ]]; then
        local saved_space=$((total_size_before - total_size_after))
        success "Compressed $total_compressed files, saved $(numfmt --to=iec $saved_space) space"
    fi
}

# Fungsi untuk menghapus log files lama
delete_old_logs() {
    local dir="$1"
    local days="$2"
    local total_deleted=0
    local total_size=0
    
    log "Deleting logs older than $days days in $dir"
    
    # Cari dan hapus file log lama
    while IFS= read -r -d '' file; do
        size=$(stat -c%s "$file" 2>/dev/null || echo 0)
        total_size=$((total_size + size))
        
        if [[ "$VERBOSE" = true ]]; then
            log "  Deleting: $file ($(get_file_size "$file"))"
        fi
        
        if [[ "$DRY_RUN" = false ]]; then
            rm -f "$file"
            if [[ $? -eq 0 ]]; then
                ((total_deleted++))
            fi
        else
            ((total_deleted++))
        fi
    done < <(find "$dir" -type f \( -name "*.log*" -o -name "*.out*" -o -name "*.err*" \) \
             -mtime +$days -print0 2>/dev/null)
    
    if [[ $total_deleted -gt 0 ]]; then
        success "Deleted $total_deleted files, freed $(numfmt --to=iec $total_size) space"
    fi
}

# Fungsi untuk generate laporan
generate_report() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        return
    fi
    
    echo
    log "=== Report for $dir ==="
    
    local log_count=$(find "$dir" -name "*.log*" -o -name "*.out*" -o -name "*.err*" 2>/dev/null | wc -l)
    local compressed_count=$(find "$dir" -name "*.gz" -o -name "*.bz2" -o -name "*.xz" 2>/dev/null | wc -l)
    local total_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    
    echo "  Total log files: $log_count"
    echo "  Compressed files: $compressed_count"
    echo "  Directory size: $total_size"
    
    # Top 5 largest files
    echo "  Largest log files:"
    find "$dir" -type f \( -name "*.log*" -o -name "*.out*" -o -name "*.err*" \) \
        -exec du -h {} + 2>/dev/null | sort -hr | head -5 | \
        while read size file; do
            echo "    $size - $(basename "$file")"
        done
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            DAYS_TO_KEEP="$2"
            shift 2
            ;;
        -c|--compress)
            DAYS_TO_COMPRESS="$2"
            shift 2
            ;;
        -p|--path)
            CUSTOM_PATHS+=("$2")
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Load konfigurasi
load_config

# Tambah custom paths jika ada
if [[ ${#CUSTOM_PATHS[@]} -gt 0 ]]; then
    LOG_DIRECTORIES+=("${CUSTOM_PATHS[@]}")
fi

# Header
echo "==============================================="
echo "         Log Cleaner Script v1.0"
echo "==============================================="
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN (Preview)" || echo "ACTIVE")"
echo "Days to keep: $DAYS_TO_KEEP"
echo "Days to compress: $DAYS_TO_COMPRESS"
echo "Directories: ${LOG_DIRECTORIES[*]}"
echo

# Proses setiap direktori
for dir in "${LOG_DIRECTORIES[@]}"; do
    if [[ -d "$dir" ]]; then
        log "Processing directory: $dir"
        
        # Compress dulu, baru delete
        compress_logs "$dir" "$DAYS_TO_COMPRESS"
        delete_old_logs "$dir" "$DAYS_TO_KEEP"
        
        if [[ "$VERBOSE" = true ]]; then
            generate_report "$dir"
        fi
        
        echo
    else
        warn "Directory not found: $dir"
    fi
done

# Summary
if [[ "$DRY_RUN" = true ]]; then
    warn "DRY RUN mode - no files were actually modified"
    echo "Run without -n flag to apply changes"
else
    success "Log cleaning completed!"
fi

# Saran untuk menjalankan secara otomatis
echo
echo "TIP: Add to crontab for automatic execution:"
echo "# Daily log cleanup at 2 AM"
echo "0 2 * * * $0 > /tmp/logcleaner.log 2>&1"
