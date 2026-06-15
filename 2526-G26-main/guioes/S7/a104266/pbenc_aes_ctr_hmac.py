import getpass
import os
import sys

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, hmac
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

ITERATIONS = 390000
SALT_SIZE = 16
NONCE_SIZE = 16
ENC_KEY_SIZE = 32
MAC_KEY_SIZE = 32
TAG_SIZE = 32


def derive_keys(password, salt):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=ENC_KEY_SIZE + MAC_KEY_SIZE,
        salt=salt,
        iterations=ITERATIONS,
    )
    material = kdf.derive(password)
    return material[:ENC_KEY_SIZE], material[ENC_KEY_SIZE:]


def build_tag(mac_key, salt, nonce, ctxt):
    mac = hmac.HMAC(mac_key, hashes.SHA256())
    mac.update(salt + nonce + ctxt)
    return mac.finalize()


def enc(fich):
    password = getpass.getpass("Pass-phrase: ").encode()
    salt = os.urandom(SALT_SIZE)
    enc_key, mac_key = derive_keys(password, salt)

    with open(fich, "rb") as f:
        ptxt = f.read()

    nonce = os.urandom(NONCE_SIZE)
    cipher = Cipher(algorithms.AES(enc_key), modes.CTR(nonce))
    encryptor = cipher.encryptor()
    ctxt = encryptor.update(ptxt) + encryptor.finalize()
    tag = build_tag(mac_key, salt, nonce, ctxt)

    with open(fich + ".enc", "wb") as f:
        f.write(salt + nonce + ctxt + tag)

    print(f"Ficheiro {fich} cifrado com AES-CTR + HMAC.")


def dec(fich):
    password = getpass.getpass("Pass-phrase: ").encode()

    with open(fich, "rb") as f:
        data = f.read()

    if len(data) < SALT_SIZE + NONCE_SIZE + TAG_SIZE:
        print("Ficheiro cifrado inválido.")
        return

    salt = data[:SALT_SIZE]
    nonce = data[SALT_SIZE:SALT_SIZE + NONCE_SIZE]
    tag = data[-TAG_SIZE:]
    ctxt = data[SALT_SIZE + NONCE_SIZE:-TAG_SIZE]
    enc_key, mac_key = derive_keys(password, salt)

    mac = hmac.HMAC(mac_key, hashes.SHA256())
    mac.update(salt + nonce + ctxt)

    try:
        mac.verify(tag)
    except InvalidSignature:
        print("MAC inválido. O ficheiro foi alterado ou a password está errada.")
        return

    cipher = Cipher(algorithms.AES(enc_key), modes.CTR(nonce))
    decryptor = cipher.decryptor()
    ptxt = decryptor.update(ctxt) + decryptor.finalize()

    out_file = fich.replace(".enc", "") + ".dec"
    with open(out_file, "wb") as f:
        f.write(ptxt)

    print(f"Ficheiro decifrado guardado em {out_file}.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 pbenc_aes_ctr_hmac.py <enc|dec> <ficheiro>")
        sys.exit(1)

    op = sys.argv[1]
    ficheiro = sys.argv[2]

    if op == "enc":
        enc(ficheiro)
    elif op == "dec":
        dec(ficheiro)
    else:
        print("Operação inválida. Use 'enc' ou 'dec'.")
        sys.exit(1)
