#!/bin/bash

# Exercicio 3
cat > pbenc_aes_ctr_hmac.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
from pathlib import Path

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, hmac
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


ENC_KEY_SIZE = 32
MAC_KEY_SIZE = 32
TOTAL_KEY_SIZE = ENC_KEY_SIZE + MAC_KEY_SIZE
SALT_SIZE = 16
IV_SIZE = 16
TAG_SIZE = 32
PBKDF2_ITER = 200000


def read_passphrase():
    line = sys.stdin.readline()
    if line == "":
        raise ValueError("missing passphrase on stdin")
    return line.rstrip("\r\n").encode("utf-8")


def derive_keys(passphrase, salt):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=TOTAL_KEY_SIZE,
        salt=salt,
        iterations=PBKDF2_ITER,
    )
    material = kdf.derive(passphrase)
    return material[:ENC_KEY_SIZE], material[ENC_KEY_SIZE:]


def calc_tag(mac_key, data):
    auth = hmac.HMAC(mac_key, hashes.SHA256())
    auth.update(data)
    return auth.finalize()


def verify_tag(mac_key, data, tag):
    auth = hmac.HMAC(mac_key, hashes.SHA256())
    auth.update(data)
    auth.verify(tag)


def aes_ctr_crypt(data, key, iv):
    cipher = Cipher(algorithms.AES(key), modes.CTR(iv))
    worker = cipher.encryptor()
    return worker.update(data) + worker.finalize()


def cmd_enc(fich):
    passphrase = read_passphrase()
    salt = os.urandom(SALT_SIZE)
    enc_key, mac_key = derive_keys(passphrase, salt)
    iv = os.urandom(IV_SIZE)
    ptxt = Path(fich).read_bytes()
    ctxt = aes_ctr_crypt(ptxt, enc_key, iv)
    body = salt + iv + ctxt
    tag = calc_tag(mac_key, body)
    Path(f"{fich}.enc").write_bytes(body + tag)


def cmd_dec(fich):
    passphrase = read_passphrase()
    blob = Path(fich).read_bytes()
    if len(blob) < (SALT_SIZE + IV_SIZE + TAG_SIZE):
        raise ValueError("ciphertext file too short")

    salt = blob[:SALT_SIZE]
    iv = blob[SALT_SIZE : SALT_SIZE + IV_SIZE]
    tag = blob[-TAG_SIZE:]
    ctxt = blob[SALT_SIZE + IV_SIZE : -TAG_SIZE]
    enc_key, mac_key = derive_keys(passphrase, salt)
    try:
        verify_tag(mac_key, salt + iv + ctxt, tag)
    except InvalidSignature:
        raise ValueError("MAC verification failed")

    ptxt = aes_ctr_crypt(ctxt, enc_key, iv)
    Path(f"{fich}.dec").write_bytes(ptxt)


def main():
    if len(sys.argv) != 3:
        print("Usage:", file=sys.stderr)
        print("  echo 'pass' | python3 pbenc_aes_ctr_hmac.py enc <fich>", file=sys.stderr)
        print("  echo 'pass' | python3 pbenc_aes_ctr_hmac.py dec <fich>", file=sys.stderr)
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
chmod +x pbenc_aes_ctr_hmac.py

# Testes
# echo "frase-passe" > pass.txt
# echo "Mensagem teste ctr+hmac" > msg.txt
# python3 pbenc_aes_ctr_hmac.py enc msg.txt < pass.txt
# python3 pbenc_aes_ctr_hmac.py dec msg.txt.enc < pass.txt
# cmp -s msg.txt msg.txt.enc.dec && echo "AES-CTR + HMAC OK"
