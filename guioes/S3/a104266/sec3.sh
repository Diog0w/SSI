#!/bin/bash

echo "=== Exercício 1: Criar programa executável ==="
# Criação do código C 
cat << 'EOF' > lerficheiro.c
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <nome_do_ficheiro>\n", argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "r");
    if (file == NULL) {
        perror("Erro ao abrir o ficheiro");
        return 1;
    }

    int ch;
    while ((ch = fgetc(file)) != EOF) {
        putchar(ch);
    }

    fclose(file);
    return 0;
}
EOF

# Compilar o programa C
gcc lerficheiro.c -o lerficheiro
echo "Programa 'lerficheiro' compilado com sucesso."


echo -e "\n=== Exercício 2: Criar utilizador userssi ==="
# Criar utilizador userssi 
id -u userssi &>/dev/null || useradd -m -s /bin/bash userssi
echo "Utilizador 'userssi' criado."


echo -e "\n=== Exercício 3: Alterar o dono para userssi ==="
# Alterar o dono do executável e do braga.txt para userssi 
chown userssi lerficheiro braga.txt
echo "Dono de 'lerficheiro' e 'braga.txt' alterado para userssi."
ls -l lerficheiro braga.txt


echo -e "\n=== Exercício 4: Executar o programa SEM setuid ==="
# O utilizador normal tenta executar o programa passando o braga.txt como argumento 
echo "Tentar ler braga.txt com o utilizador normal (vboxuser)..."
sudo -u vboxuser ./lerficheiro braga.txt


echo -e "\n=== Exercício 5: Definir permissão setuid ==="
# Definir a permissão setuid no executável [cite: 80, 91]
chmod 4755 lerficheiro
echo "Permissão setuid (s) adicionada ao executável."
ls -l lerficheiro


echo -e "\n=== Exercício 6: Executar o programa COM setuid ==="
# Repetir o ponto 4 [cite: 92]
echo "Tentar ler braga.txt com o utilizador normal (vboxuser) novamente..."
sudo -u vboxuser ./lerficheiro braga.txt

# COMENTÁRIO SOBRE O RESULTADO: [cite: 93]
# No Exercício 4, recebemos "Permission denied" porque o utilizador que executa o comando
# não tem permissões de leitura no braga.txt.
# No Exercício 6, a leitura funciona! O ficheiro executável tem a permissão 'setuid' ativada.
# Isto faz com que o processo assuma temporariamente (utilizador efetivo) os privilégios 
# do dono do ficheiro executável ('userssi'). Como o dono do 'braga.txt' também é o 'userssi'
# e tem permissão de leitura, o programa consegue abrir e ler o ficheiro.