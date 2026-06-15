#!/bin/bash

# Exercicio 1
cat > bad_otp.py << 'EOF'
#!/usr/bin/env python3
import random
import sys
from pathlib import Path


def xor_bytes(a, b):
    return bytes(x ^ y for x, y in zip(a, b))


def bad_prng(n):
    random.seed(random.randbytes(2))
    return random.randbytes(n)


def setup_key(nbytes, key_path):
    if nbytes <= 0:
        raise ValueError("number of bytes must be > 0")
    Path(key_path).write_bytes(bad_prng(nbytes))


def crypt_file(in_path, key_path):
    data = Path(in_path).read_bytes()
    key = Path(key_path).read_bytes()
    if len(key) < len(data):
        raise ValueError("key is shorter than input data")
    return xor_bytes(data, key[: len(data)])


def main():
    if len(sys.argv) != 4:
        print("Usage:", file=sys.stderr)
        print("  python3 bad_otp.py setup <NBYTES> <KEY_FILE>", file=sys.stderr)
        print("  python3 bad_otp.py enc <INPUT_FILE> <KEY_FILE>", file=sys.stderr)
        print("  python3 bad_otp.py dec <INPUT_FILE> <KEY_FILE>", file=sys.stderr)
        return 1

    mode = sys.argv[1]
    if mode == "setup":
        try:
            nbytes = int(sys.argv[2])
        except ValueError:
            print("NBYTES must be an integer", file=sys.stderr)
            return 1
        setup_key(nbytes, sys.argv[3])
        return 0

    if mode in {"enc", "dec"}:
        out = crypt_file(sys.argv[2], sys.argv[3])
        sys.stdout.buffer.write(out)
        return 0

    print("mode must be setup, enc or dec", file=sys.stderr)
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        raise SystemExit(1)
EOF
chmod +x bad_otp.py

# Testes
# python3 bad_otp.py setup 30 bad.key
# echo "Mensagem a cifrar" > ptxt.txt
# python3 bad_otp.py enc ptxt.txt bad.key > ptxt_bad.enc
# python3 bad_otp.py dec ptxt_bad.enc bad.key > ptxt_bad.dec
# cat ptxt_bad.dec
