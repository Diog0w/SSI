import sys

def preproc(s):
    return "".join([c.upper() for c in s if c.isalpha()])

def main():
    if len(sys.argv) != 4:
        print("Uso: python3 vigenere.py <enc|dec> <chave_palavra> <mensagem>")
        return

    op = sys.argv[1]
    key = preproc(sys.argv[2])
    msg = preproc(sys.argv[3])
    resultado = ""

    for i, char in enumerate(msg):
        shift = ord(key[i % len(key)]) - ord('A')
        if op == "enc":
            novo_char = chr(((ord(char) - ord('A') + shift) % 26) + ord('A'))
        else:
            novo_char = chr(((ord(char) - ord('A') - shift) % 26) + ord('A'))
        resultado += novo_char

    print(resultado)

if __name__ == "__main__":
    main()
