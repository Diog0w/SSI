#!/bin/bash

# Exercicio 1
cat > mac_sha256.py << 'EOF'
#!/usr/bin/env python3
import hashlib
import hmac
import os
import sys
from pathlib import Path


KEY_SIZE = 32
TAG_SIZE = hashlib.sha256().digest_size


def read_key(path):
    key = Path(path).read_bytes()
    if len(key) != KEY_SIZE:
        raise ValueError("invalid key size for SHA256 prefix-MAC (expected 32 bytes)")
    return key


def calc_mac(key, data):
    return hashlib.sha256(key + data).digest()


def cmd_setup(fkey):
    Path(fkey).write_bytes(os.urandom(KEY_SIZE))


def cmd_mac(fich, fkey):
    key = read_key(fkey)
    data = Path(fich).read_bytes()
    Path(f"{fich}.mac").write_bytes(calc_mac(key, data))


def cmd_ver(fich, fkey):
    key = read_key(fkey)
    data = Path(fich).read_bytes()
    tag = Path(f"{fich}.mac").read_bytes()
    if len(tag) != TAG_SIZE:
        raise ValueError("invalid MAC size")
    print(hmac.compare_digest(calc_mac(key, data), tag))


def main():
    if len(sys.argv) < 3:
        print("Usage:", file=sys.stderr)
        print("  python3 mac_sha256.py setup <fkey>", file=sys.stderr)
        print("  python3 mac_sha256.py mac <fich> <fkey>", file=sys.stderr)
        print("  python3 mac_sha256.py ver <fich> <fkey>", file=sys.stderr)
        return 1

    cmd = sys.argv[1]
    if cmd == "setup" and len(sys.argv) == 3:
        cmd_setup(sys.argv[2])
        return 0
    if cmd == "mac" and len(sys.argv) == 4:
        cmd_mac(sys.argv[2], sys.argv[3])
        return 0
    if cmd == "ver" and len(sys.argv) == 4:
        cmd_ver(sys.argv[2], sys.argv[3])
        return 0

    print("invalid arguments", file=sys.stderr)
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        raise SystemExit(1)
EOF
chmod +x mac_sha256.py

# Testes
# python3 mac_sha256.py setup mac.key
# echo -n "mensagem de teste" > msg.txt
# python3 mac_sha256.py mac msg.txt mac.key
# python3 mac_sha256.py ver msg.txt mac.key
