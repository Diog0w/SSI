import sys
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

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
    
    # Gerar um Nonce de 16 bytes para o modo CTR
    nonce = os.urandom(16)
    
    # Configurar cifra AES no modo CTR
    cipher = Cipher(algorithms.AES(key), modes.CTR(nonce))
    encryptor = cipher.encryptor()
    ctxt = encryptor.update(ptxt) + encryptor.finalize()
    
    # Guardar o Nonce seguido do criptograma
    with open(fich + ".enc", "wb") as f:
        f.write(nonce + ctxt)

def dec(fich, fkey):
    with open(fkey, "rb") as f:
        key = f.read()
    with open(fich, "rb") as f:
        data = f.read()
    
    # Separar o Nonce (primeiros 16 bytes) do criptograma
    nonce = data[:16]
    ctxt = data[16:]
    
    # Decifrar AES no modo CTR
    cipher = Cipher(algorithms.AES(key), modes.CTR(nonce))
    decryptor = cipher.decryptor()
    ptxt = decryptor.update(ctxt) + decryptor.finalize()
    
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