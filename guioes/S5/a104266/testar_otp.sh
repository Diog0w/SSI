#!/bin/bash

# 1. CRIAR otp.py 
cat << 'EOF' > otp.py
import sys
import secrets

def xor_bytes(data, key):
    return bytes([b1 ^ b2 for b1, b2 in zip(data, key)])

def main():
    if len(sys.argv) < 4:
        return

    op = sys.argv[1]

    if op == "setup":
        num_bytes = int(sys.argv[2])
        key_file = sys.argv[3]
        chave = secrets.token_bytes(num_bytes)
        with open(key_file, "wb") as f:
            f.write(chave)

    elif op == "enc":
        msg_file = sys.argv[2]
        key_file = sys.argv[3]
        out_file = msg_file + ".enc"
        with open(msg_file, "rb") as f_msg, open(key_file, "rb") as f_key:
            msg_data = f_msg.read()
            key_data = f_key.read()
        with open(out_file, "wb") as f_out:
            f_out.write(xor_bytes(msg_data, key_data))

    elif op == "dec":
        ctxt_file = sys.argv[2]
        key_file = sys.argv[3]
        out_file = ctxt_file + ".dec"
        with open(ctxt_file, "rb") as f_ctxt, open(key_file, "rb") as f_key:
            ctxt_data = f_ctxt.read()
            key_data = f_key.read()
        with open(out_file, "wb") as f_out:
            f_out.write(xor_bytes(ctxt_data, key_data))

if __name__ == "__main__":
    main()
EOF

# 2. CRIAR bad_otp.py
cat << 'EOF' > bad_otp.py
import sys
import random

def bad_prng(n):
    """ an INSECURE pseudo-random number generator """
    random.seed(random.randbytes(2))
    return random.randbytes(n)

def xor_bytes(data, key):
    return bytes([b1 ^ b2 for b1, b2 in zip(data, key)])

def main():
    if len(sys.argv) < 4:
        return

    op = sys.argv[1]

    if op == "setup":
        num_bytes = int(sys.argv[2])
        key_file = sys.argv[3]
        chave = bad_prng(num_bytes)
        with open(key_file, "wb") as f:
            f.write(chave)

    elif op == "enc":
        msg_file = sys.argv[2]
        key_file = sys.argv[3]
        out_file = msg_file + ".enc"
        with open(msg_file, "rb") as f_msg, open(key_file, "rb") as f_key:
            msg_data = f_msg.read()
            key_data = f_key.read()
        with open(out_file, "wb") as f_out:
            f_out.write(xor_bytes(msg_data, key_data))

    elif op == "dec":
        ctxt_file = sys.argv[2]
        key_file = sys.argv[3]
        out_file = ctxt_file + ".dec"
        with open(ctxt_file, "rb") as f_ctxt, open(key_file, "rb") as f_key:
            ctxt_data = f_ctxt.read()
            key_data = f_key.read()
        with open(out_file, "wb") as f_out:
            f_out.write(xor_bytes(ctxt_data, key_data))

if __name__ == "__main__":
    main()
EOF

# 3. CRIAR bad_otp_attack.py
cat << 'EOF' > bad_otp_attack.py
import sys
import random

def xor_bytes(data, key):
    return bytes([b1 ^ b2 for b1, b2 in zip(data, key)])

def main():
    if len(sys.argv) < 3:
        print("Uso: python3 bad_otp_attack.py <criptograma> <palavra1> [palavra2 ...]")
        return

    ctxt_file = sys.argv[1]
    palavras = [p.encode() for p in sys.argv[2:]] # Converter palavras para bytes

    with open(ctxt_file, "rb") as f:
        ctxt_data = f.read()

    n = len(ctxt_data)

    # Força bruta: testar as 65536 sementes possíveis (2 bytes)
    for i in range(65536):
        seed_bytes = i.to_bytes(2, byteorder='big')
        random.seed(seed_bytes)
        key_data = random.randbytes(n)

        texto_limpo = xor_bytes(ctxt_data, key_data)

        # Verifica se alguma das palavras fornecidas existe no texto limpo gerado
        if any(palavra in texto_limpo for palavra in palavras):
            print(f"[!] Semente encontrada: {seed_bytes.hex()}")
            print(texto_limpo.decode(errors='ignore'))
            return

    print("[-] Não foi possível quebrar a cifra com as palavras fornecidas.")

if __name__ == "__main__":
    main()
EOF

echo "Ficheiros Python gerados com sucesso."

echo -e "\n========================================================="
echo " Teste 1: Versão Segura (otp.py)                         "
echo "========================================================="
echo "Mensagem muito secreta a cifrar" > ptxt.txt
python3 otp.py setup 31 otp.key
python3 otp.py enc ptxt.txt otp.key
python3 otp.py dec ptxt.txt.enc otp.key
echo "Resultado da decifragem segura:"
cat ptxt.txt.enc.dec

echo -e "\n\n========================================================="
echo " Teste 2: Versão Insegura (bad_otp.py)                   "
echo "========================================================="
echo "O tesouro esta enterrado na arvore velha" > bad_ptxt.txt
python3 bad_otp.py setup 40 bad_otp.key
python3 bad_otp.py enc bad_ptxt.txt bad_otp.key
python3 bad_otp.py dec bad_ptxt.txt.enc bad_otp.key
echo "Resultado da decifragem insegura:"
cat bad_ptxt.txt.enc.dec

echo -e "\n\n========================================================="
echo " Teste 3: Ataque à Versão Insegura (bad_otp_attack.py)   "
echo "========================================================="
echo "A executar ataque de força bruta..."
python3 bad_otp_attack.py bad_ptxt.txt.enc tesouro arvore
