import re
import sys

KEY_SIZE = 32
MASK = 0xFFFFFFFF
K = [
    0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5,
    0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
    0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3,
    0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
    0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC,
    0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
    0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7,
    0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
    0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13,
    0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
    0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3,
    0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
    0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5,
    0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
    0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208,
    0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
]


def right_rotate(value, shift):
    return ((value >> shift) | (value << (32 - shift))) & MASK


def sha256_padding(msg_len):
    padding = b"\x80"
    while (msg_len + len(padding) + 8) % 64 != 0:
        padding += b"\x00"
    padding += (msg_len * 8).to_bytes(8, "big")
    return padding


def parse_mac(mac_hex):
    mac_hex = mac_hex.strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", mac_hex):
        raise ValueError("MAC inválido: esperado digest SHA256 em hexadecimal.")
    return [int(mac_hex[i:i + 8], 16) for i in range(0, 64, 8)]


def sha256_compress(chunk, state):
    w = [0] * 64
    for i in range(16):
        w[i] = int.from_bytes(chunk[i * 4:(i + 1) * 4], "big")

    for i in range(16, 64):
        s0 = right_rotate(w[i - 15], 7) ^ right_rotate(w[i - 15], 18) ^ (w[i - 15] >> 3)
        s1 = right_rotate(w[i - 2], 17) ^ right_rotate(w[i - 2], 19) ^ (w[i - 2] >> 10)
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & MASK

    a, b, c, d, e, f, g, h = state

    for i in range(64):
        s1 = right_rotate(e, 6) ^ right_rotate(e, 11) ^ right_rotate(e, 25)
        ch = (e & f) ^ ((~e) & g)
        temp1 = (h + s1 + ch + K[i] + w[i]) & MASK
        s0 = right_rotate(a, 2) ^ right_rotate(a, 13) ^ right_rotate(a, 22)
        maj = (a & b) ^ (a & c) ^ (b & c)
        temp2 = (s0 + maj) & MASK

        h = g
        g = f
        f = e
        e = (d + temp1) & MASK
        d = c
        c = b
        b = a
        a = (temp1 + temp2) & MASK

    return [
        (state[0] + a) & MASK,
        (state[1] + b) & MASK,
        (state[2] + c) & MASK,
        (state[3] + d) & MASK,
        (state[4] + e) & MASK,
        (state[5] + f) & MASK,
        (state[6] + g) & MASK,
        (state[7] + h) & MASK,
    ]


def forge_mac(original_mac, original_len, ext):
    state = parse_mac(original_mac)
    glue_padding = sha256_padding(KEY_SIZE + original_len)
    processed_len = KEY_SIZE + original_len + len(glue_padding)
    data = ext + sha256_padding(processed_len + len(ext))

    for offset in range(0, len(data), 64):
        state = sha256_compress(data[offset:offset + 64], state)

    forged_mac = "".join(f"{value:08x}" for value in state)
    return glue_padding, forged_mac


def attack(fich, ext_text):
    ext = ext_text.encode()

    with open(fich, "rb") as f:
        original_msg = f.read()
    with open(fich + ".mac", "r", encoding="ascii") as f:
        original_mac = f.read().strip()

    glue_padding, forged_mac = forge_mac(original_mac, len(original_msg), ext)
    extended_msg = original_msg + glue_padding + ext

    with open(fich + ".ext", "wb") as f:
        f.write(extended_msg)
    with open(fich + ".ext.mac", "w", encoding="ascii") as f:
        f.write(forged_mac + "\n")

    print(f"Mensagem estendida gravada em {fich}.ext.")
    print(f"MAC forjado gravado em {fich}.ext.mac.")
    print(f"Padding acrescentado (hex): {glue_padding.hex()}")
    print(f"Tamanho do padding: {len(glue_padding)} bytes.")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python3 mac_sha256_attack.py <fich> <ext>")
        sys.exit(1)

    attack(sys.argv[1], sys.argv[2])
