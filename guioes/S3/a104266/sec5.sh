#!/bin/bash

echo "=== Exercício 1: Listar todas as capabilities disponíveis ==="
# Lista as capabilities disponíveis no sistema usando capsh --print
capsh --print | head -n 10
echo "(...)"

echo -e "\n=== Exercício 2: Criar e compilar programa em C (webserver.c) ==="
# Criação do código C 
cat << 'EOF' > webserver.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <port>\n", argv[0]);
        return 1;
    }
    
    int port = atoi(argv[1]);
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    
    if (sockfd < 0) {
        perror("Error when creating socket");
        return 1;
    }
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    
    if (bind(sockfd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("Error on bind");
        close(sockfd);
        return 1;
    }
    
    printf("Success: binded to port %d\n", port);
    close(sockfd);
    return 0;
}
EOF

# Compilar o programa
gcc webserver.c -o webserver
echo "Programa 'webserver' compilado com sucesso."

# Fazer bind à porta 4050
echo -e "\n-> A testar bind na porta 4050 como vboxuser:"
sudo -u vboxuser ./webserver 4050


echo -e "\n=== Exercício 3: Executar o programa na porta 80 ==="
# Executar o programa anterior sobre a porta 80
echo "-> A testar bind na porta 80 como vboxuser (SEM capabilities):"
sudo -u vboxuser ./webserver 80

# Qual o resultado obtido, e qual o motivo?
# RESULTADO: Dá erro "Permission denied". 
# MOTIVO: Portas abaixo de 1024 são privilegiadas e exigem permissões de root.

echo -e "\n-> A aplicar capability 'cap_net_bind_service'..."
# Como poderiam ser utilizadas as capabilities para executar o programa?
# Usando o setcap para atribuir a capability que permite binding a portas < 1024
setcap cap_net_bind_service=+ep ./webserver

echo "-> A testar bind na porta 80 como vboxuser (COM capabilities):"
sudo -u vboxuser ./webserver 80
