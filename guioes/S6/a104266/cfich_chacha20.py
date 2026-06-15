import sys
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms

def setup(fkey):
    # ChaCha20 utiliza uma chave de 32 bytes (256 bits)
    key = os.urandom(32)
    with open(fkey, "wb") as f:
        f.write(key)

def enc(fich, fkey):
    with open(fkey, "rb") as f:
        key = f.read()
    with open(fich, "rb") as f:
        ptxt = f.read()
    
    nonce = os.urandom(16) # Nonce de 16 bytes para ChaCha20 na lib cryptography
    cipher = Cipher(algorithms.ChaCha20(key, nonce), mode=None)
    encryptor = cipher.encryptor()
    ctxt = encryptor.update(ptxt)
    
    # Grava o nonce seguido do criptograma para permitir a decifragem
    with open(fich + ".enc", "wb") as f:
        f.write(nonce + ctxt)

def dec(fich, fkey):
    with open(fkey, "rb") as f:
        key = f.read()
    with open(fich, "rb") as f:
        data = f.read()
    
    nonce = data[:16]
    ctxt = data[16:]
    
    cipher = Cipher(algorithms.ChaCha20(key, nonce), mode=None)
    decryptor = cipher.decryptor()
    ptxt = decryptor.update(ctxt)
    
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