#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Jalankan sebagai root (sudo)."
    exit 1
fi

usage() {
    echo "Cara pakai: $0 [action] [type] [value]"
    echo "Action: allow/deny"
    echo "Type: port/ip/interface"
    echo "Contoh:"
    echo "  $0 allow port 80"
    echo "  $0 deny ip 192.168.1.1"
    echo "  $0 allow interface eth0 from 192.168.1.0/24"
    echo "Tambahan: status/reset/log"
    exit 1
}

if [ $# -lt 3 ] && [ "$1" != "status" ] && [ "$1" != "reset" ] && [ "$1" != "log" ]; then
    usage
fi

ACTION=$1
TYPE=$2
VALUE=$3

case $1 in
    status)
        sudo ufw status verbose
        ;;
    reset)
        sudo ufw reset
        ;;
    log)
        sudo ufw logging on
        echo "Logging diaktifkan."
        ;;
    allow|deny)
        case $TYPE in
            port)
                sudo ufw $ACTION $VALUE
                ;;
            ip)
                sudo ufw $ACTION from $VALUE
                ;;
            interface)
                if [ $# -lt 5 ] || [ "$4" != "from" ]; then
                    usage
                fi
                sudo ufw $ACTION in on $VALUE from $5
                ;;
            *)
                usage
                ;;
        esac
        ;;
    *)
        usage
        ;;
esac

echo "Perubahan diterapkan. Cek status: sudo ufw status."
