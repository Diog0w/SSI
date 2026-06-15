import sys

def preproc(s):
    l = []
    for c in s:
        if c.isalpha():
            l.append(c.upper())
    return "".join(l)

def main():
    if len(sys.argv) != 4:
        print("Uso: python3 cesar.py <enc|dec> <chave_letra> <mensagem>")
        return

    op = sys.argv[1]
    key_char = sys.argv[2].upper()
    msg = sys.argv[3]

    shift = ord(key_char) - ord('A')
    texto_processado = preproc(msg)
    resultado = ""

    for char in texto_processado:
        if op == "enc":
            novo_char = chr(((ord(char) - ord('A') + shift) % 26) + ord('A'))
        elif op == "dec":
            novo_char = chr(((ord(char) - ord('A') - shift) % 26) + ord('A'))
        resultado += novo_char

    print(resultado)

if __name__ == "__main__":
    main()
