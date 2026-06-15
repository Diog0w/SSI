#!/bin/bash

# Exercicio 1
cat > vigenere.py << 'EOF'
#!/usr/bin/env python3
import sys


def preproc(s):
    return "".join(c.upper() for c in s if c.isalpha())


def shift_char(c, shift):
    return chr((ord(c) - ord("A") + shift) % 26 + ord("A"))


def crypt(mode, key, message):
    out = []
    key_shifts = [ord(k) - ord("A") for k in key]
    for i, c in enumerate(message):
        shift = key_shifts[i % len(key_shifts)]
        if mode == "dec":
            shift = -shift
        out.append(shift_char(c, shift))
    return "".join(out)


def main():
    if len(sys.argv) != 4:
        print("Usage: python3 vigenere.py <enc|dec> <KEY_WORD> <MESSAGE>", file=sys.stderr)
        return 1

    mode, key, message = sys.argv[1], sys.argv[2], sys.argv[3]
    if mode not in {"enc", "dec"}:
        print("mode must be enc or dec", file=sys.stderr)
        return 1

    key = preproc(key)
    if not key:
        print("key must contain at least one letter", file=sys.stderr)
        return 1

    message = preproc(message)
    print(crypt(mode, key, message))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
chmod +x vigenere.py

# Exercicio 2
cat > vigenere_attack.py << 'EOF'
#!/usr/bin/env python3
import itertools
import sys


PT_FREQ = {
    "A": 0.1463, "B": 0.0104, "C": 0.0388, "D": 0.0499, "E": 0.1257, "F": 0.0102,
    "G": 0.0130, "H": 0.0128, "I": 0.0618, "J": 0.0040, "K": 0.0002, "L": 0.0278,
    "M": 0.0474, "N": 0.0505, "O": 0.1073, "P": 0.0252, "Q": 0.0120, "R": 0.0653,
    "S": 0.0781, "T": 0.0434, "U": 0.0463, "V": 0.0167, "W": 0.0001, "X": 0.0021,
    "Y": 0.0001, "Z": 0.0047,
}


def preproc(s):
    return "".join(c.upper() for c in s if c.isalpha())


def decrypt_with_key_shifts(ciphertext, key_shifts):
    out = []
    klen = len(key_shifts)
    for i, c in enumerate(ciphertext):
        shift = key_shifts[i % klen]
        out.append(chr((ord(c) - ord("A") - shift) % 26 + ord("A")))
    return "".join(out)


def chi_square_text(text):
    n = len(text)
    if n == 0:
        return float("inf")
    counts = {ch: 0 for ch in PT_FREQ}
    for c in text:
        counts[c] += 1
    chi = 0.0
    for ch, freq in PT_FREQ.items():
        expected = n * freq
        if expected > 0:
            obs = counts[ch]
            chi += (obs - expected) ** 2 / expected
    return chi


def candidate_rank(plaintext, words):
    matched = sum(1 for w in words if w and w in plaintext)
    if matched == 0:
        return None
    # Preferir:
    # 1) mais palavras-pista encontradas
    # 2) texto mais plausivel em portugues (chi-square menor)
    return matched, chi_square_text(plaintext)


def shifts_to_key(key_shifts):
    return "".join(chr(ord("A") + s) for s in key_shifts)


def best_shifts_for_slice(slice_text, top_n):
    if not slice_text:
        return [0]

    ranked = []
    n = len(slice_text)
    for shift in range(26):
        decrypted = [chr((ord(c) - ord("A") - shift) % 26 + ord("A")) for c in slice_text]
        counts = {ch: 0 for ch in PT_FREQ}
        for c in decrypted:
            counts[c] += 1

        chi = 0.0
        for ch, freq in PT_FREQ.items():
            expected = n * freq
            if expected > 0:
                obs = counts[ch]
                chi += (obs - expected) ** 2 / expected
        ranked.append((chi, shift))

    ranked.sort(key=lambda x: x[0])
    return [shift for _, shift in ranked[:top_n]]


def crack_bruteforce(key_len, ciphertext, words):
    best = None
    for key_shifts in itertools.product(range(26), repeat=key_len):
        plaintext = decrypt_with_key_shifts(ciphertext, key_shifts)
        rank = candidate_rank(plaintext, words)
        if rank is None:
            continue
        if best is None:
            best = (rank[0], rank[1], key_shifts, plaintext)
            continue
        if rank[0] > best[0] or (rank[0] == best[0] and rank[1] < best[1]):
            best = (rank[0], rank[1], key_shifts, plaintext)
    if best is None:
        return None, None
    return best[2], best[3]


def crack_by_frequency(key_len, ciphertext, words, top_n):
    candidates = []
    for i in range(key_len):
        slice_text = ciphertext[i::key_len]
        candidates.append(best_shifts_for_slice(slice_text, top_n))

    best = None
    for key_shifts in itertools.product(*candidates):
        plaintext = decrypt_with_key_shifts(ciphertext, key_shifts)
        rank = candidate_rank(plaintext, words)
        if rank is None:
            continue
        if best is None:
            best = (rank[0], rank[1], key_shifts, plaintext)
            continue
        if rank[0] > best[0] or (rank[0] == best[0] and rank[1] < best[1]):
            best = (rank[0], rank[1], key_shifts, plaintext)
    if best is None:
        return None, None
    return best[2], best[3]


def main():
    if len(sys.argv) < 4:
        print(
            "Usage: python3 vigenere_attack.py <KEY_SIZE> <CIPHERTEXT> <WORD1> [WORD2...]",
            file=sys.stderr,
        )
        return 1

    try:
        key_len = int(sys.argv[1])
    except ValueError:
        print("KEY_SIZE must be an integer", file=sys.stderr)
        return 1

    if key_len <= 0:
        print("KEY_SIZE must be > 0", file=sys.stderr)
        return 1

    ciphertext = preproc(sys.argv[2])
    words = [preproc(w) for w in sys.argv[3:]]
    words = [w for w in words if w]
    if not words:
        print("at least one search word is required", file=sys.stderr)
        return 1

    key_shifts = None
    plaintext = None

    if key_len <= 4:
        key_shifts, plaintext = crack_bruteforce(key_len, ciphertext, words)

    if key_shifts is None:
        for top_n in (4, 8):
            key_shifts, plaintext = crack_by_frequency(key_len, ciphertext, words, top_n)
            if key_shifts is not None:
                break

    if key_shifts is not None:
        print(shifts_to_key(key_shifts))
        print(plaintext)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
chmod +x vigenere_attack.py

# Testes
# python3 vigenere.py enc BACO "CifraIndecifravel"
# python3 vigenere.py dec BACO "DIHFBIPRFCKTSAXSM"
# python3 vigenere_attack.py 3 "PGRGARHSFHPRGCVHOJHWEPZRSCJFIVSOFRWUTBKPZGGOZPZLHWKPBR" PAPO PRAIA
