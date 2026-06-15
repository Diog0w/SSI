import sys

def attack(fctxt, pos, ptxtAtPos, newPtxtAtPos):
    with open(fctxt, "rb") as f:
        data = bytearray(f.read())
    
    # O ficheiro contem o NONCE (16 bytes) no inicio, o criptograma comeca no indice 16
    offset = 16 + int(pos)
    
    ptxt_bytes = ptxtAtPos.encode()
    new_ptxt_bytes = newPtxtAtPos.encode()
    
    for i in range(len(ptxt_bytes)):
        # Matematica: C_new = C_old XOR P_old XOR P_new
        data[offset + i] = data[offset + i] ^ ptxt_bytes[i] ^ new_ptxt_bytes[i]
        
    with open(fctxt + ".attck", "wb") as f:
        f.write(data)

if __name__ == "__main__":
    # Argumentos: <fctxt> <pos> <ptxtAtPos> <newPtxtAtPos> 
    attack(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]) # 