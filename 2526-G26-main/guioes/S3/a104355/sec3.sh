#!/bin/bash

# Exercício 1 - Criar programa leitor
cat << EOF > leitor.c
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Uso: %s ficheiro\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "r");
    if (!f) {
        perror("Erro ao abrir ficheiro");
        return 1;
    }

    char c;
    while ((c = fgetc(f)) != EOF) {
        putchar(c);
    }

    fclose(f);
    return 0;
}
EOF

gcc leitor.c -o leitor

# Exercício 2
sudo adduser userssi

# Exercício 3
sudo chown userssi:userssi leitor
sudo chown userssi:userssi braga.txt
ls -l leitor braga.txt

# Exercício 4
./leitor braga.txt

# Exercício 5
sudo chmod u+s leitor
ls -l leitor

# Exercício 6
./leitor braga.txt
# Agora o programa corre com UID efetivo de userssi devido ao SetUID.
