#!/bin/bash

# Exercicio 3
cat > cfich_aes_cbc.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
from pathlib import Path

from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


KEY_SIZE = 32
IV_SIZE = 16


def read_key(path):
    key = Path(path).read_bytes()
    if len(key) != KEY_SIZE:
        raise ValueError("invalid key size for AES-256 (expected 32 bytes)")
    return key


def cmd_setup(fkey):
    Path(fkey).write_bytes(os.urandom(KEY_SIZE))


def cmd_enc(fich, fkey):
    key = read_key(fkey)
    iv = os.urandom(IV_SIZE)
    ptxt = Path(fich).read_bytes()

    padder = padding.PKCS7(128).padder()
    padded = padder.update(ptxt) + padder.finalize()

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    enc = cipher.encryptor()
    ctxt = enc.update(padded) + enc.finalize()
    Path(f"{fich}.enc").write_bytes(iv + ctxt)


def cmd_dec(fich, fkey):
    key = read_key(fkey)
    blob = Path(fich).read_bytes()
    if len(blob) < IV_SIZE:
        raise ValueError("ciphertext file too short")
    iv = blob[:IV_SIZE]
    ctxt = blob[IV_SIZE:]

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    dec = cipher.decryptor()
    padded = dec.update(ctxt) + dec.finalize()

    unpadder = padding.PKCS7(128).unpadder()
    ptxt = unpadder.update(padded) + unpadder.finalize()
    Path(f"{fich}.dec").write_bytes(ptxt)


def main():
    if len(sys.argv) < 3:
        print("Usage:", file=sys.stderr)
        print("  python3 cfich_aes_cbc.py setup <fkey>", file=sys.stderr)
        print("  python3 cfich_aes_cbc.py enc <fich> <fkey>", file=sys.stderr)
        print("  python3 cfich_aes_cbc.py dec <fich> <fkey>", file=sys.stderr)
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
chmod +x cfich_aes_cbc.py

# Testes
# python3 cfich_aes_cbc.py setup aes.key
# python3 cfich_aes_cbc.py enc msg.txt aes.key
# python3 cfich_aes_cbc.py dec msg.txt.enc aes.key
