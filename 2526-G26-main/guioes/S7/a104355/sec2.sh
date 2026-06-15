#!/bin/bash

# Exercicio 2
cat > mac_sha256_attack.py << 'EOF'
#!/usr/bin/env python3
import struct
import sys
from pathlib import Path


KEY_SIZE = 32
BLOCK_SIZE = 64
DIGEST_SIZE = 32
MASK32 = 0xFFFFFFFF
INITIAL_STATE = [
    0x6A09E667,
    0xBB67AE85,
    0x3C6EF372,
    0xA54FF53A,
    0x510E527F,
    0x9B05688C,
    0x1F83D9AB,
    0x5BE0CD19,
]
K = [
    0x428A2F98,
    0x71374491,
    0xB5C0FBCF,
    0xE9B5DBA5,
    0x3956C25B,
    0x59F111F1,
    0x923F82A4,
    0xAB1C5ED5,
    0xD807AA98,
    0x12835B01,
    0x243185BE,
    0x550C7DC3,
    0x72BE5D74,
    0x80DEB1FE,
    0x9BDC06A7,
    0xC19BF174,
    0xE49B69C1,
    0xEFBE4786,
    0x0FC19DC6,
    0x240CA1CC,
    0x2DE92C6F,
    0x4A7484AA,
    0x5CB0A9DC,
    0x76F988DA,
    0x983E5152,
    0xA831C66D,
    0xB00327C8,
    0xBF597FC7,
    0xC6E00BF3,
    0xD5A79147,
    0x06CA6351,
    0x14292967,
    0x27B70A85,
    0x2E1B2138,
    0x4D2C6DFC,
    0x53380D13,
    0x650A7354,
    0x766A0ABB,
    0x81C2C92E,
    0x92722C85,
    0xA2BFE8A1,
    0xA81A664B,
    0xC24B8B70,
    0xC76C51A3,
    0xD192E819,
    0xD6990624,
    0xF40E3585,
    0x106AA070,
    0x19A4C116,
    0x1E376C08,
    0x2748774C,
    0x34B0BCB5,
    0x391C0CB3,
    0x4ED8AA4A,
    0x5B9CCA4F,
    0x682E6FF3,
    0x748F82EE,
    0x78A5636F,
    0x84C87814,
    0x8CC70208,
    0x90BEFFFA,
    0xA4506CEB,
    0xBEF9A3F7,
    0xC67178F2,
]


def rotr(x, n):
    return ((x >> n) | (x << (32 - n))) & MASK32


def ch(x, y, z):
    return (x & y) ^ (~x & z)


def maj(x, y, z):
    return (x & y) ^ (x & z) ^ (y & z)


def bsig0(x):
    return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22)


def bsig1(x):
    return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25)


def ssig0(x):
    return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3)


def ssig1(x):
    return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10)


def sha256_padding(message_length):
    pad = b"\x80"
    pad += b"\x00" * ((56 - ((message_length + 1) % BLOCK_SIZE)) % BLOCK_SIZE)
    pad += (message_length * 8).to_bytes(8, "big")
    return pad


def compress(state, chunk):
    words = list(struct.unpack(">16I", chunk)) + [0] * 48
    for i in range(16, 64):
        words[i] = (
            ssig1(words[i - 2]) + words[i - 7] + ssig0(words[i - 15]) + words[i - 16]
        ) & MASK32

    a, b, c, d, e, f, g, h = state
    for i in range(64):
        t1 = (h + bsig1(e) + ch(e, f, g) + K[i] + words[i]) & MASK32
        t2 = (bsig0(a) + maj(a, b, c)) & MASK32
        h = g
        g = f
        f = e
        e = (d + t1) & MASK32
        d = c
        c = b
        b = a
        a = (t1 + t2) & MASK32

    return [
        (state[0] + a) & MASK32,
        (state[1] + b) & MASK32,
        (state[2] + c) & MASK32,
        (state[3] + d) & MASK32,
        (state[4] + e) & MASK32,
        (state[5] + f) & MASK32,
        (state[6] + g) & MASK32,
        (state[7] + h) & MASK32,
    ]


class SHA256:
    def __init__(self, state=None, count=0):
        if state is None:
            self._state = list(INITIAL_STATE)
        else:
            if len(state) != 8:
                raise ValueError("invalid internal SHA256 state")
            if count % BLOCK_SIZE != 0:
                raise ValueError("byte count must be a multiple of 64 when resuming state")
            self._state = list(state)
        self._count = count
        self._buffer = b""

    def update(self, data):
        if not data:
            return self
        self._buffer += data
        while len(self._buffer) >= BLOCK_SIZE:
            chunk = self._buffer[:BLOCK_SIZE]
            self._buffer = self._buffer[BLOCK_SIZE:]
            self._state = compress(self._state, chunk)
            self._count += BLOCK_SIZE
        return self

    def digest(self):
        state = list(self._state)
        final = self._buffer + sha256_padding(self._count + len(self._buffer))
        for off in range(0, len(final), BLOCK_SIZE):
            state = compress(state, final[off : off + BLOCK_SIZE])
        return struct.pack(">8I", *state)


def read_tag(path):
    tag = Path(path).read_bytes()
    if len(tag) != DIGEST_SIZE:
        raise ValueError("invalid MAC size")
    return tag


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 mac_sha256_attack.py <fich> <ext>", file=sys.stderr)
        return 1

    fich = sys.argv[1]
    ext = sys.argv[2].encode("utf-8")

    msg = Path(fich).read_bytes()
    tag = read_tag(f"{fich}.mac")
    glue = sha256_padding(KEY_SIZE + len(msg))

    state = struct.unpack(">8I", tag)
    forged = SHA256(state=state, count=KEY_SIZE + len(msg) + len(glue))
    forged.update(ext)
    new_tag = forged.digest()

    Path(f"{fich}.ext").write_bytes(msg + glue + ext)
    Path(f"{fich}.ext.mac").write_bytes(new_tag)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        raise SystemExit(1)
EOF
chmod +x mac_sha256_attack.py

# Testes
# python3 mac_sha256_attack.py msg.txt "&admin=true"
# python3 mac_sha256.py ver msg.txt.ext mac.key
