#!/bin/sh
set -e

usage() {
    echo "Usage: osc-copy [FILE]"
    echo "       command | osc-copy"
    echo ""
    echo "Copy input to system clipboard via OSC 52 escape sequence."
    echo "Works over SSH and inside tmux."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  echo 'hello' | osc-copy"
    echo "  osc-copy file.txt"
    echo "  cat ~/.ssh/id_ed25519.pub | osc-copy"
}

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
esac

if [ -n "$1" ]; then
    if [ ! -f "$1" ]; then
        echo "osc-copy: $1: No such file" >&2
        exit 1
    fi
    data=$(base64 < "$1" | tr -d '\n')
else
    data=$(base64 | tr -d '\n')
fi

if [ -n "$TMUX" ]; then
    printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "$data"
else
    printf '\033]52;c;%s\a' "$data"
fi
