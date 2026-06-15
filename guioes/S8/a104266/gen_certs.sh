#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

cleanup_old_files() {
    rm -f CA.srl Alice.csr Bob.csr
}

create_leaf_cert() {
    local name="$1"
    openssl req -new -key "${name}.key" -out "${name}.csr" -subj "/CN=${name}"
    openssl x509 -req \
        -in "${name}.csr" \
        -CA CA.crt \
        -CAkey CA.key \
        -CAcreateserial \
        -out "${name}.crt" \
        -days 365 \
        -sha256
}

cleanup_old_files

openssl genrsa -out CA.key 2048
openssl genrsa -out Alice.key 2048
openssl genrsa -out Bob.key 2048

openssl req -x509 -new -nodes \
    -key CA.key \
    -sha256 \
    -days 365 \
    -out CA.crt \
    -subj "/CN=CA"

create_leaf_cert Alice
create_leaf_cert Bob

echo "Certificados e chaves gerados em $SCRIPT_DIR"
