import hashlib
import hmac
import os
import sys

KEY_SIZE = 32


def prefix_mac(key, data):
    digest = hashlib.sha256()
    digest.update(key)
    digest.update(data)
    return digest.hexdigest()


def setup(fkey):
    with open(fkey, "wb") as f:
        f.write(os.urandom(KEY_SIZE))
    print(f"Chave MAC gerada em {fkey}.")


def mac_file(fich, fkey):
    with open(fkey, "rb") as f:
        key = f.read()
    with open(fich, "rb") as f:
        data = f.read()

    mac_hex = prefix_mac(key, data)
    with open(fich + ".mac", "w", encoding="ascii") as f:
        f.write(mac_hex + "\n")

    print(f"MAC gravado em {fich}.mac.")


def verify_file(fich, fkey):
    with open(fkey, "rb") as f:
        key = f.read()
    with open(fich, "rb") as f:
        data = f.read()
    with open(fich + ".mac", "r", encoding="ascii") as f:
        stored_mac = f.read().strip()

    computed_mac = prefix_mac(key, data)
    print(hmac.compare_digest(computed_mac, stored_mac))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 mac_sha256.py <setup|mac|ver> <ficheiro> [fkey]")
        sys.exit(1)

    op = sys.argv[1]

    if op == "setup" and len(sys.argv) == 3:
        setup(sys.argv[2])
    elif op == "mac" and len(sys.argv) == 4:
        mac_file(sys.argv[2], sys.argv[3])
    elif op == "ver" and len(sys.argv) == 4:
        verify_file(sys.argv[2], sys.argv[3])
    else:
        print("Uso: python3 mac_sha256.py <setup|mac|ver> <ficheiro> [fkey]")
        sys.exit(1)
