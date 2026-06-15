#!/usr/bin/env python3
import os
from multiprocessing import Pipe, Process
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import dh, padding
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.x509.oid import NameOID


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
SCRIPT_DIR = Path(__file__).resolve().parent
REQUIRED_FILES = ("CA.crt", "Alice.key", "Alice.crt", "Bob.key", "Bob.crt")


def build_parameters():
    prime = int("".join(P_HEX.split()), 16)
    numbers = dh.DHParameterNumbers(prime, G)
    return numbers.parameters()


def encode_dh_public_key(public_key):
    return public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )


def decode_dh_public_key(blob):
    return serialization.load_pem_public_key(blob)


def derive_session_key(shared_secret):
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=AES_KEY_SIZE,
        salt=None,
        info=b"ssi-semana8-sts-aes-gcm",
    )
    return hkdf.derive(shared_secret)


def seal(key, plaintext, aad):
    nonce = os.urandom(NONCE_SIZE)
    cipher = AESGCM(key)
    return nonce + cipher.encrypt(nonce, plaintext, aad)


def open_seal(key, blob, aad):
    if len(blob) < NONCE_SIZE + 16:
        raise ValueError("criptograma demasiado curto")
    nonce = blob[:NONCE_SIZE]
    ciphertext = blob[NONCE_SIZE:]
    cipher = AESGCM(key)
    return cipher.decrypt(nonce, ciphertext, aad)


def pack_fields(*chunks):
    output = len(chunks).to_bytes(2, "big")
    for chunk in chunks:
        output += len(chunk).to_bytes(4, "big") + chunk
    return output


def unpack_fields(blob):
    if len(blob) < 2:
        raise ValueError("bloco demasiado curto")
    count = int.from_bytes(blob[:2], "big")
    cursor = 2
    values = []
    for _ in range(count):
        if len(blob) < cursor + 4:
            raise ValueError("cabecalho truncado")
        size = int.from_bytes(blob[cursor : cursor + 4], "big")
        cursor += 4
        if len(blob) < cursor + size:
            raise ValueError("campo truncado")
        values.append(blob[cursor : cursor + size])
        cursor += size
    if cursor != len(blob):
        raise ValueError("dados extra encontrados")
    return values


def load_private_key(path):
    return serialization.load_pem_private_key(path.read_bytes(), password=None)


def load_certificate(path):
    return x509.load_pem_x509_certificate(path.read_bytes())


def verify_certificate(cert_pem, ca_certificate, expected_common_name):
    cert = x509.load_pem_x509_certificate(cert_pem)
    ca_certificate.public_key().verify(
        cert.signature,
        cert.tbs_certificate_bytes,
        padding.PKCS1v15(),
        cert.signature_hash_algorithm,
    )
    if cert.issuer != ca_certificate.subject:
        raise ValueError("emissor do certificado nao corresponde a CA")
    common_names = cert.subject.get_attributes_for_oid(NameOID.COMMON_NAME)
    if not common_names or common_names[0].value != expected_common_name:
        raise ValueError(f"certificado inesperado para {expected_common_name}")
    return cert


def sign_sts_values(private_key, first_value, second_value):
    payload = pack_fields(first_value, second_value)
    return private_key.sign(
        payload,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH,
        ),
        hashes.SHA256(),
    )


def verify_sts_signature(public_key, signature, first_value, second_value):
    payload = pack_fields(first_value, second_value)
    public_key.verify(
        signature,
        payload,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH,
        ),
        hashes.SHA256(),
    )


def alice_process(conn):
    ca_certificate = load_certificate(SCRIPT_DIR / "CA.crt")
    alice_private_key = load_private_key(SCRIPT_DIR / "Alice.key")
    alice_certificate_pem = (SCRIPT_DIR / "Alice.crt").read_bytes()

    dh_private_key = build_parameters().generate_private_key()
    alice_dh_bytes = encode_dh_public_key(dh_private_key.public_key())
    conn.send(alice_dh_bytes)

    bob_packet = conn.recv()
    bob_dh_bytes, bob_signature, bob_certificate_pem = unpack_fields(bob_packet)

    bob_certificate = verify_certificate(bob_certificate_pem, ca_certificate, "Bob")
    verify_sts_signature(
        bob_certificate.public_key(),
        bob_signature,
        bob_dh_bytes,
        alice_dh_bytes,
    )

    bob_dh_public_key = decode_dh_public_key(bob_dh_bytes)
    shared_secret = dh_private_key.exchange(bob_dh_public_key)
    print(f"Alice K: {shared_secret.hex()}", flush=True)

    alice_signature = sign_sts_values(alice_private_key, alice_dh_bytes, bob_dh_bytes)
    conn.send(pack_fields(alice_signature, alice_certificate_pem))

    aes_key = derive_session_key(shared_secret)
    conn.send(seal(aes_key, b"Ola Bob, canal autenticado por STS.", b"alice->bob"))

    reply = open_seal(aes_key, conn.recv(), b"bob->alice")
    print(f"Alice recebeu: {reply.decode('utf-8')}", flush=True)


def bob_process(conn):
    ca_certificate = load_certificate(SCRIPT_DIR / "CA.crt")
    bob_private_key = load_private_key(SCRIPT_DIR / "Bob.key")
    bob_certificate_pem = (SCRIPT_DIR / "Bob.crt").read_bytes()

    dh_private_key = build_parameters().generate_private_key()
    bob_dh_bytes = encode_dh_public_key(dh_private_key.public_key())

    alice_dh_bytes = conn.recv()
    bob_signature = sign_sts_values(bob_private_key, bob_dh_bytes, alice_dh_bytes)
    conn.send(pack_fields(bob_dh_bytes, bob_signature, bob_certificate_pem))

    alice_packet = conn.recv()
    alice_signature, alice_certificate_pem = unpack_fields(alice_packet)

    alice_certificate = verify_certificate(alice_certificate_pem, ca_certificate, "Alice")
    verify_sts_signature(
        alice_certificate.public_key(),
        alice_signature,
        alice_dh_bytes,
        bob_dh_bytes,
    )

    alice_dh_public_key = decode_dh_public_key(alice_dh_bytes)
    shared_secret = dh_private_key.exchange(alice_dh_public_key)
    print(f"Bob K:   {shared_secret.hex()}", flush=True)

    aes_key = derive_session_key(shared_secret)
    message = open_seal(aes_key, conn.recv(), b"alice->bob")
    print(f"Bob recebeu: {message.decode('utf-8')}", flush=True)

    conn.send(seal(aes_key, b"Ola Alice, certificado e assinatura validados.", b"bob->alice"))


def main():
    missing = [name for name in REQUIRED_FILES if not (SCRIPT_DIR / name).exists()]
    if missing:
        raise FileNotFoundError(
            "Faltam ficheiros de certificados/chaves: "
            + ", ".join(missing)
            + ". Executa primeiro ./gen_certs.sh"
        )

    left, right = Pipe()
    alice = Process(target=alice_process, args=(left,))
    bob = Process(target=bob_process, args=(right,))
    alice.start()
    bob.start()
    alice.join()
    bob.join()


if __name__ == "__main__":
    main()
