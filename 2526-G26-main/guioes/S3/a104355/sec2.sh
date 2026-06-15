#!/bin/bash

# Exercício 0
cat /etc/passwd | head
cat /etc/group | head

# Exercício 1
# Nota: se já tiverem sido criados antes, estes comandos podem falhar com "already exists".
sudo adduser a104355
sudo adduser a104533
sudo adduser a104266

# Exercício 2
sudo groupadd grupo-ssi
sudo groupadd par-ssi

sudo usermod -aG grupo-ssi a104355
sudo usermod -aG grupo-ssi a104533
sudo usermod -aG grupo-ssi a104266

sudo usermod -aG par-ssi a104355
sudo usermod -aG par-ssi a104533

# Exercício 3
grep -E "a104355|a104533|a104266" /etc/passwd
grep -E "grupo-ssi|par-ssi" /etc/group
# Diferenças observadas: novas entradas em /etc/passwd para os utilizadores e novos grupos em /etc/group.

# Exercício 4
sudo chown a104355 braga.txt
ls -l braga.txt

# Exercício 5
cat braga.txt
# Esperado: "Permission denied" porque braga.txt está em 400 e agora pertence a a104355.

# Exercício 6
# Em vez de "su - a104355" (que prende o script), corremos comandos como a104355 e voltamos.
su - a104355 -c 'echo "Sessão iniciada como a104355 (via su -c)"'

# Exercício 7
su - a104355 -c 'id; groups'
# O output mostra UID/GID de a104355 e os grupos (incluindo grupo-ssi e possivelmente par-ssi).

# Exercício 8
su - a104355 -c 'cat /home/ssi/S3/braga.txt'
# Esperado: pode falhar se o utilizador não tiver permissão de execução
# nas diretorias do caminho (/home/ssi).
# O acesso a um ficheiro depende também das permissões das pastas no caminho.

# Exercício 9
su - a104355 -c 'cd /home/ssi/S3/dir2'
# Esperado: falha, porque dir2 removeu "x" para group/others (só o dono tem execução).
# Para confirmar, podes trocar por: su - a104355 -c 'cd /home/ssi/S3/dir2 || echo "Sem permissao para entrar em dir2"'
