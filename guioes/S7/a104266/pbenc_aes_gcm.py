import getpass
import os
import sys

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

ITERATIONS = 390000
SALT_SIZE = 16
NONCE_SIZE = 12
KEY_SIZE = 32


def derive_key(password, salt):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=KEY_SIZE,
        salt=salt,
        iterations=ITERATIONS,
    )
    return kdf.derive(password)


def enc(fich):
    password = getpass.getpass("Pass-phrase: ").encode()
    salt = os.urandom(SALT_SIZE)
    key = derive_key(password, salt)

    with open(fich, "rb") as f:
        ptxt = f.read()

    nonce = os.urandom(NONCE_SIZE)
    aesgcm = AESGCM(key)
    ctxt = aesgcm.encrypt(nonce, ptxt, None)

    with open(fich + ".enc", "wb") as f:
        f.write(salt + nonce + ctxt)

    print(f"Ficheiro {fich} cifrado com AES-GCM.")


def dec(fich):
    password = getpass.getpass("Pass-phrase: ").encode()

    with open(fich, "rb") as f:
        data = f.read()

    if len(data) < SALT_SIZE + NONCE_SIZE + 16:
        print("Ficheiro cifrado inválido.")
        return

    salt = data[:SALT_SIZE]
    nonce = data[SALT_SIZE:SALT_SIZE + NONCE_SIZE]
    ctxt = data[SALT_SIZE + NONCE_SIZE:]
    key = derive_key(password, salt)

    aesgcm = AESGCM(key)
    try:
        ptxt = aesgcm.decrypt(nonce, ctxt, None)
    except InvalidTag:
        print("Autenticação falhou. O ficheiro foi alterado ou a password está errada.")
        return

    out_file = fich.replace(".enc", "") + ".dec"
    with open(out_file, "wb") as f:
        f.write(ptxt)

    print(f"Ficheiro decifrado guardado em {out_file}.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 pbenc_aes_gcm.py <enc|dec> <ficheiro>")
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
