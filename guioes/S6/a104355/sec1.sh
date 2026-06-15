#!/bin/bash

# Exercicio 1
cat > cfich_chacha20.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
from pathlib import Path

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms


KEY_SIZE = 32
NONCE_SIZE = 16


def read_key(path):
    key = Path(path).read_bytes()
    if len(key) != KEY_SIZE:
        raise ValueError("invalid key size for ChaCha20 (expected 32 bytes)")
    return key


def chacha20_crypt(data, key, nonce):
    cipher = Cipher(algorithms.ChaCha20(key, nonce), mode=None)
    worker = cipher.encryptor()
    return worker.update(data) + worker.finalize()


def cmd_setup(fkey):
    Path(fkey).write_bytes(os.urandom(KEY_SIZE))


def cmd_enc(fich, fkey):
    key = read_key(fkey)
    nonce = os.urandom(NONCE_SIZE)
    ptxt = Path(fich).read_bytes()
    ctxt = chacha20_crypt(ptxt, key, nonce)
    Path(f"{fich}.enc").write_bytes(nonce + ctxt)


def cmd_dec(fich, fkey):
    key = read_key(fkey)
    blob = Path(fich).read_bytes()
    if len(blob) < NONCE_SIZE:
        raise ValueError("ciphertext file too short")
    nonce = blob[:NONCE_SIZE]
    ctxt = blob[NONCE_SIZE:]
    ptxt = chacha20_crypt(ctxt, key, nonce)
    Path(f"{fich}.dec").write_bytes(ptxt)


def main():
    if len(sys.argv) < 3:
        print("Usage:", file=sys.stderr)
        print("  python3 cfich_chacha20.py setup <fkey>", file=sys.stderr)
        print("  python3 cfich_chacha20.py enc <fich> <fkey>", file=sys.stderr)
        print("  python3 cfich_chacha20.py dec <fich> <fkey>", file=sys.stderr)
        return 1

    cmd = sys.argv[1]
    if cmd == "setup" and len(sys.argv) == 3:
        cmd_setup(sys.argv[2])
        return 0
    if cmd == "enc" and len(sys.argv) == 4:
        cmd_enc(sys.argv[2], sys.argv[3])
        return 0
    if cmd == "dec" and len(sys.argv) == 4:
        cmd_dec(sys.argv[2], sys.argv[3])
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
chmod +x cfich_chacha20.py

# Testes
# python3 cfich_chacha20.py setup c20.key
# echo "Mensagem teste" > msg.txt
# python3 cfich_chacha20.py enc msg.txt c20.key
# python3 cfich_chacha20.py dec msg.txt.enc c20.key
# cat msg.txt.enc.dec
