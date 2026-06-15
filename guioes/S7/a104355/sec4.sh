#!/bin/bash

# Exercicio 4
cat > pbenc_aes_gcm.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
from pathlib import Path

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


KEY_SIZE = 32
SALT_SIZE = 16
NONCE_SIZE = 12
PBKDF2_ITER = 200000


def read_passphrase():
    line = sys.stdin.readline()
    if line == "":
        raise ValueError("missing passphrase on stdin")
    return line.rstrip("\r\n").encode("utf-8")


def derive_key(passphrase, salt):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=KEY_SIZE,
        salt=salt,
        iterations=PBKDF2_ITER,
    )
    return kdf.derive(passphrase)


def cmd_enc(fich):
    passphrase = read_passphrase()
    salt = os.urandom(SALT_SIZE)
    key = derive_key(passphrase, salt)
    nonce = os.urandom(NONCE_SIZE)
    ptxt = Path(fich).read_bytes()
    aesgcm = AESGCM(key)
    ctxt = aesgcm.encrypt(nonce, ptxt, salt)
    Path(f"{fich}.enc").write_bytes(salt + nonce + ctxt)


def cmd_dec(fich):
    passphrase = read_passphrase()
    blob = Path(fich).read_bytes()
    if len(blob) < (SALT_SIZE + NONCE_SIZE + 16):
        raise ValueError("ciphertext file too short")

    salt = blob[:SALT_SIZE]
    nonce = blob[SALT_SIZE : SALT_SIZE + NONCE_SIZE]
    ctxt = blob[SALT_SIZE + NONCE_SIZE :]
    key = derive_key(passphrase, salt)
    aesgcm = AESGCM(key)
    ptxt = aesgcm.decrypt(nonce, ctxt, salt)
    Path(f"{fich}.dec").write_bytes(ptxt)


def main():
    if len(sys.argv) != 3:
        print("Usage:", file=sys.stderr)
        print("  echo 'pass' | python3 pbenc_aes_gcm.py enc <fich>", file=sys.stderr)
        print("  echo 'pass' | python3 pbenc_aes_gcm.py dec <fich>", file=sys.stderr)
        return 1

    cmd = sys.argv[1]
    fich = sys.argv[2]
    if cmd == "enc":
        cmd_enc(fich)
        return 0
    if cmd == "dec":
        cmd_dec(fich)
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
chmod +x pbenc_aes_gcm.py

# Testes
# echo "frase-passe" > pass.txt
# echo "Mensagem teste gcm" > msg.txt
# python3 pbenc_aes_gcm.py enc msg.txt < pass.txt
# python3 pbenc_aes_gcm.py dec msg.txt.enc < pass.txt
# cmp -s msg.txt msg.txt.enc.dec && echo "AES-GCM OK"
