import sys

def main():
    if len(sys.argv) < 3:
        print("Uso: python3 cesar_attack.py <criptograma> <palavra1> [palavra2 ...]")
        return

    criptograma = sys.argv[1].upper()
    palavras = [p.upper() for p in sys.argv[2:]]

    for shift in range(26):
        texto_limpo = ""
        for char in criptograma:
            novo_char = chr(((ord(char) - ord('A') - shift) % 26) + ord('A'))
            texto_limpo += novo_char
        
        # Verifica se alguma das palavras existe no texto limpo gerado
        if any(palavra in texto_limpo for palavra in palavras):
            chave = chr(shift + ord('A'))
            print(chave)
            print(texto_limpo)
            return
            
    # Resposta vazia em caso de falha

if __name__ == "__main__":
    main()
