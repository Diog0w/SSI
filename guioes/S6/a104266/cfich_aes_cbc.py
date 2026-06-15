import sys
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

def setup(fkey):
    # Gerar uma chave de 32 bytes para AES-256
    key = os.urandom(32)
    with open(fkey, "wb") as f:
        f.write(key)

def enc(fich, fkey):
    with open(fkey, "rb") as f:
        key = f.read()
    with open(fich, "rb") as f:
        ptxt = f.read()
    
    # Gerar um IV (Initialization Vector) de 16 bytes
    iv = os.urandom(16)
    
    # Aplicar Padding PKCS7 (128 bits = 16 bytes)
    padder = padding.PKCS7(128).padder()
    padded_ptxt = padder.update(ptxt) + padder.finalize()
    
    # Configurar cifra AES no modo CBC
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    encryptor = cipher.encryptor()
    ctxt = encryptor.update(padded_ptxt) + encryptor.finalize()
    
    # Guardar o IV seguido do criptograma
    with open(fich + ".enc", "wb") as f:
        f.write(iv + ctxt)

def dec(fich, fkey):
    with open(fkey, "rb") as f:
        key = f.read()
    with open(fich, "rb") as f:
        data = f.read()
    
    # Separar IV (primeiros 16 bytes) do criptograma
    iv = data[:16]
    ctxt = data[16:]
    
    # Decifrar AES no modo CBC
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    decryptor = cipher.decryptor()
    padded_ptxt = decryptor.update(ctxt) + decryptor.finalize()
    
    # Remover o Padding PKCS7
    unpadder = padding.PKCS7(128).unpadder()
    ptxt = unpadder.update(padded_ptxt) + unpadder.finalize()
    
    # Guardar texto-limpo
    with open(fich.replace(".enc", "") + ".dec", "wb") as f:
        f.write(ptxt)

if __name__ == "__main__":
    op = sys.argv[1]
    if op == "setup":
        setup(sys.argv[2])
    elif op == "enc":
        enc(sys.argv[2], sys.argv[3])
    elif op == "dec":
        dec(sys.argv[2], sys.argv[3])