#!/bin/bash

# Exercicio 2
cat > chacha20_int_attck.py << 'EOF'
#!/usr/bin/env python3
import sys
from pathlib import Path


NONCE_SIZE = 16


def parse_pos(s):
    try:
        pos = int(s)
    except ValueError:
        raise ValueError("pos must be an integer")
    if pos < 0:
        raise ValueError("pos must be >= 0")
    return pos


def main():
    if len(sys.argv) != 5:
        print(
            "Usage: python3 chacha20_int_attck.py <fctxt> <pos> <ptxtAtPos> <newPtxtAtPos>",
            file=sys.stderr,
        )
        return 1

    fctxt = sys.argv[1]
    pos = parse_pos(sys.argv[2])
    old = sys.argv[3].encode("utf-8")
    new = sys.argv[4].encode("utf-8")
    if len(old) != len(new):
        raise ValueError("ptxtAtPos and newPtxtAtPos must have same length")

    blob = Path(fctxt).read_bytes()
    if len(blob) < NONCE_SIZE:
        raise ValueError("ciphertext file too short")

    nonce = blob[:NONCE_SIZE]
    ctxt = bytearray(blob[NONCE_SIZE:])

    if pos + len(old) > len(ctxt):
        raise ValueError("known fragment out of bounds")

    for i in range(len(old)):
        ctxt[pos + i] ^= old[i] ^ new[i]

    Path(f"{fctxt}.attck").write_bytes(nonce + bytes(ctxt))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        raise SystemExit(1)
EOF
chmod +x chacha20_int_attck.py

# Testes
# python3 chacha20_int_attck.py msg.txt.enc 0 Mensagem XXXXXXXX
# python3 cfich_chacha20.py dec msg.txt.enc.attck c20.key
