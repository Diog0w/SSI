#!/bin/bash

echo "=== Preparação: Instalar dependências (ACL) ==="
# Instalar o pacote acl (conforme a nota do guião)
apt update && apt install acl -y

echo -e "\n=== Exercício 1: Executar getfacl para o ficheiro porto.txt ==="
# Verificar as permissões normais antes da ACL
getfacl porto.txt

echo -e "\n=== Exercício 2: Definir permissões de escrita para o grupo grupo-ssi ==="
# A flag -m serve para modificar/adicionar uma regra ACL
# g:grupo-ssi:w indica -> group : nome_do_grupo : write
setfacl -m g:grupo-ssi:w porto.txt
echo "Permissão de escrita (w) concedida ao grupo 'grupo-ssi' no ficheiro porto.txt."

echo -e "\n=== Exercício 3: Executar getfacl para o ficheiro porto.txt e comentar ==="
getfacl porto.txt

# COMENTÁRIO EXERCÍCIO 3:
# A diferença face ao ponto 1 é a adição de uma linha 'group:grupo-ssi:-w-'.
# Isto indica que, independentemente das permissões do dono ou do grupo principal,
# o grupo-ssi tem uma regra de exceção para poder escrever no ficheiro.
# Adicionalmente, também aparece uma linha 'mask::rwx' que define o limite máximo
# de permissões ativas. Se fizermos 'ls -l porto.txt', veríamos um '+' no final
# das permissões (ex: -r-x--w---+), indicando que o ficheiro tem ACLs ativas.


echo -e "\n=== Exercício 4: Iniciar sessão como utilizador do grupo, alterar e ler ==="
echo "A tentar escrever no porto.txt como 'aluno1' (membro do grupo-ssi)..."
# Usamos bash -c para garantir que o redirecionamento (>>) é feito com os privilégios do aluno1
sudo -u aluno1 bash -c 'echo "O aluno1 esteve aqui e escreveu via ACL!" >> porto.txt'
echo "Escrita concluída."

echo "A tentar ler o ficheiro porto.txt como 'aluno1'..."
sudo -u aluno1 cat porto.txt || echo "-> O comando 'cat' falhou."

# COMENTÁRIO EXERCÍCIO 4:
# Análise do resultado: O utilizador 'aluno1' conseguiu escrever (adicionar texto) no
# ficheiro porque lhe foi concedida a permissão 'w' via ACL estendida através do grupo-ssi.
# No entanto, a tentativa de leitura (cat) FALHOU com "Permission denied"!
# Porquê? Porque a ACL estendida apenas concedeu permissão de escrita explícita. 
# Como as permissões base (definidas na Secção 1) dão apenas acesso de leitura ao dono, 
# o 'aluno1' (que é apenas membro de um grupo secundário com ACL) fica com capacidade 
# para escrever, mas sem direitos para ler o que acabou de escrever.
