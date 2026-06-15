#!/usr/bin/env python3
import os
from multiprocessing import Pipe, Process

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import dh
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF


P_HEX = """
FFFFFFFF FFFFFFFF C90FDAA2 2168C234 C4C6628B
80DC1CD1 29024E08 8A67CC74 020BBEA6 3B139B22
514A0879 8E3404DD EF9519B3 CD3A431B 302B0A6D
F25F1437 4FE1356D 6D51C245 E485B576 625E7EC6
F44C42E9 A637ED6B 0BFF5CB6 F406B7ED EE386BFB
5A899FA5 AE9F2411 7C4B1FE6 49286651 ECE45B3D
C2007CB8 A163BF05 98DA4836 1C55D39A 69163FA8
FD24CF5F 83655D23 DCA3AD96 1C62F356 208552BB
9ED52907 7096966D 670C354E 4ABC9804 F1746C08
CA18217C 32905E46 2E36CE3B E39E772C 180E8603
9B2783A2 EC07A28F B5C55DF0 6F4C52C9 DE2BCBF6
95581718 3995497C EA956AE5 15D22618 98FA0510
15728E5A 8AACAA68 FFFFFFFF FFFFFFFF
"""
G = 2
NONCE_SIZE = 12
AES_KEY_SIZE = 32


def build_parameters():
    prime = int("".join(P_HEX.split()), 16)
    numbers = dh.DHParameterNumbers(prime, G)
    return numbers.parameters()


def encode_public_key(public_key):
    return public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )


def decode_public_key(blob):
    return serialization.load_pem_public_key(blob)


def derive_session_key(shared_secret):
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=AES_KEY_SIZE,
        salt=None,
        info=b"ssi-semana8-dh-aes-gcm",
    )
    return hkdf.derive(shared_secret)


def seal(key, plaintext, aad):
    nonce = os.urandom(NONCE_SIZE)
    cipher = AESGCM(key)
    ciphertext = cipher.encrypt(nonce, plaintext, aad)
    return nonce + ciphertext


def open_seal(key, blob, aad):
    if len(blob) < NONCE_SIZE + 16:
        raise ValueError("criptograma demasiado curto")
    nonce = blob[:NONCE_SIZE]
    ciphertext = blob[NONCE_SIZE:]
    cipher = AESGCM(key)
    return cipher.decrypt(nonce, ciphertext, aad)


def alice_process(conn):
    private_key = build_parameters().generate_private_key()
    public_bytes = encode_public_key(private_key.public_key())

    conn.send(public_bytes)
    peer_bytes = conn.recv()

    peer_public_key = decode_public_key(peer_bytes)
    shared_secret = private_key.exchange(peer_public_key)
    print(f"Alice K: {shared_secret.hex()}", flush=True)

    aes_key = derive_session_key(shared_secret)
    conn.send(seal(aes_key, b"Mensagem confidencial da Alice para o Bob.", b"alice->bob"))

    reply = open_seal(aes_key, conn.recv(), b"bob->alice")
    print(f"Alice recebeu: {reply.decode('utf-8')}", flush=True)


def bob_process(conn):
    private_key = build_parameters().generate_private_key()
    public_bytes = encode_public_key(private_key.public_key())

    peer_bytes = conn.recv()
    conn.send(public_bytes)

    peer_public_key = decode_public_key(peer_bytes)
    shared_secret = private_key.exchange(peer_public_key)
    print(f"Bob K:   {shared_secret.hex()}", flush=True)

    aes_key = derive_session_key(shared_secret)
    message = open_seal(aes_key, conn.recv(), b"alice->bob")
    print(f"Bob recebeu: {message.decode('utf-8')}", flush=True)

    conn.send(seal(aes_key, b"Resposta confidencial do Bob para a Alice.", b"bob->alice"))


def main():
    left, right = Pipe()
    alice = Process(target=alice_process, args=(left,))
    bob = Process(target=bob_process, args=(right,))
    alice.start()
    bob.start()
    alice.join()
    bob.join()


if __name__ == "__main__":
    main()
