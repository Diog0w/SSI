#!/bin/bash

# Exercicio 1
cat > bad_otp_attack.py << 'EOF'
#!/usr/bin/env python3
import random
import sys
from pathlib import Path


def preproc(s):
    return "".join(c.upper() for c in s if c.isalpha())


def xor_bytes(a, b):
    return bytes(x ^ y for x, y in zip(a, b))


def decode_guess(data):
    for enc in ("utf-8", "latin-1"):
        try:
            return data.decode(enc)
        except UnicodeDecodeError:
            pass
    return data.decode("latin-1", errors="ignore")


def main():
    if len(sys.argv) < 4:
        print(
            "Usage: python3 bad_otp_attack.py <KEY_SIZE> <CIPHERTEXT_FILE> <WORD1> [WORD2...]",
            file=sys.stderr,
        )
        return 1

    try:
        key_size = int(sys.argv[1])
    except ValueError:
        print("KEY_SIZE must be an integer", file=sys.stderr)
        return 1

    if key_size <= 0:
        print("KEY_SIZE must be > 0", file=sys.stderr)
        return 1

    ciphertext = Path(sys.argv[2]).read_bytes()
    if len(ciphertext) > key_size:
        print("ciphertext is longer than key_size", file=sys.stderr)
        return 1

    words = [preproc(w) for w in sys.argv[3:]]
    words = [w for w in words if w]
    if not words:
        print("at least one search word is required", file=sys.stderr)
        return 1

    for seed_int in range(2 ** 16):
        seed = seed_int.to_bytes(2, byteorder="big")
        random.seed(seed)
        key = random.randbytes(key_size)
        plaintext_bytes = xor_bytes(ciphertext, key[: len(ciphertext)])
        plaintext = decode_guess(plaintext_bytes)
        normalized = preproc(plaintext)
        if any(w in normalized for w in words):
            sys.stdout.write(plaintext)
            if not plaintext.endswith("\n"):
                sys.stdout.write("\n")
            return 0

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        raise SystemExit(1)
EOF
chmod +x bad_otp_attack.py

# Testes
# python3 bad_otp.py setup 30 otp_bad.key
# echo "Mensagem a cifrar" > ptxt.txt
# python3 bad_otp.py enc ptxt.txt otp_bad.key > ptxt.txt.enc
# python3 bad_otp_attack.py 30 ptxt.txt.enc texto cifrar
