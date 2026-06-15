#!/bin/bash

# Exercicio 1
cat > cesar.py << 'EOF'
#!/usr/bin/env python3
import sys


def preproc(s):
    return "".join(c.upper() for c in s if c.isalpha())


def shift_char(c, shift):
    return chr((ord(c) - ord("A") + shift) % 26 + ord("A"))


def main():
    if len(sys.argv) != 4:
        print("Usage: python3 cesar.py <enc|dec> <KEY_LETTER> <MESSAGE>", file=sys.stderr)
        return 1

    mode, key, message = sys.argv[1], sys.argv[2], sys.argv[3]
    if mode not in {"enc", "dec"}:
        print("mode must be enc or dec", file=sys.stderr)
        return 1

    key = preproc(key)
    if len(key) != 1:
        print("key must be one letter A..Z", file=sys.stderr)
        return 1

    shift = ord(key) - ord("A")
    if mode == "dec":
        shift = -shift

    message = preproc(message)
    print("".join(shift_char(c, shift) for c in message))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
chmod +x cesar.py

# Exercicio 2
cat > cesar_attack.py << 'EOF'
#!/usr/bin/env python3
import sys


def preproc(s):
    return "".join(c.upper() for c in s if c.isalpha())


def decrypt_caesar(ciphertext, key_shift):
    return "".join(chr((ord(c) - ord("A") - key_shift) % 26 + ord("A")) for c in ciphertext)


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 cesar_attack.py <CIPHERTEXT> <WORD1> [WORD2...]", file=sys.stderr)
        return 1

    ciphertext = preproc(sys.argv[1])
    words = [preproc(w) for w in sys.argv[2:]]
    words = [w for w in words if w]

    for key_shift in range(26):
        plaintext = decrypt_caesar(ciphertext, key_shift)
        if any(w in plaintext for w in words):
            print(chr(ord("A") + key_shift))
            print(plaintext)
            return 0

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
chmod +x cesar_attack.py

# Testes
# python3 cesar.py enc G "CartagoEstaNoPapo"
# python3 cesar.py dec G "IGXZGMUKYZGTUVGVU"
# python3 cesar_attack.py "IGXZGMUKYZGTUVGVU" BACO PAPO
