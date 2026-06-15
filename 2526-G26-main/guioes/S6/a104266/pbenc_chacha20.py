import sys
import os
import getpass
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms

def derive_key(password, salt):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=390000,
    )
    return kdf.derive(password)

def enc(fich):
    # Lê a password de forma segura a partir do stdin
    password = getpass.getpass("Pass-phrase: ").encode()
    salt = os.urandom(16)
    key = derive_key(password, salt)
    
    with open(fich, "rb") as f:
        ptxt = f.read()
        
    nonce = os.urandom(16)
    cipher = Cipher(algorithms.ChaCha20(key, nonce), mode=None)
    ctxt = cipher.encryptor().update(ptxt)
    
    with open(fich + ".enc", "wb") as f:
        # Guarda Salt + Nonce + Criptograma no mesmo ficheiro
        f.write(salt + nonce + ctxt)
    print(f"Ficheiro {fich} cifrado com sucesso.")

def dec(fich):
    # Lê a password de forma segura a partir do stdin
    password = getpass.getpass("Pass-phrase: ").encode()
    
    with open(fich, "rb") as f:
        data = f.read()
        
    # Extrai o Salt (primeiros 16 bytes) e o Nonce (próximos 16 bytes)
    salt = data[:16]
    nonce = data[16:32]
    ctxt = data[32:]
    
    # Deriva a chave com o salt lido do ficheiro
    key = derive_key(password, salt)
    
    # Decifra
    cipher = Cipher(algorithms.ChaCha20(key, nonce), mode=None)
    ptxt = cipher.decryptor().update(ctxt)
    
    # Grava o texto limpo recuperado
    out_file = fich.replace(".enc", "") + ".dec"
    with open(out_file, "wb") as f:
        f.write(ptxt)
    print(f"Ficheiro decifrado guardado em {out_file}.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 pbenc_chacha20.py <op> <ficheiro>")
        print("Operações válidas: enc, dec")
        sys.exit(1)
        
    op = sys.argv[1]
    ficheiro = sys.argv[2]
    
    if op == "enc":
        enc(ficheiro)
    elif op == "dec":
        dec(ficheiro)
    else:
        print("Operação inválida. Use 'enc' ou 'dec'.")