#!/bin/bash

# Exercício 1: 
sudo adduser a104266
sudo adduser a104533
sudo adduser a104355

# Exercício 2: 
sudo groupadd grupo-ssi
sudo groupadd par-ssi

# Adicionar ao grupo-ssi
sudo usermod -aG grupo-ssi a104266
sudo usermod -aG grupo-ssi a104533
sudo usermod -aG grupo-ssi a104355

# Adicionar apenas 2 elementos ao par-ssi
sudo usermod -aG par-ssi a104266
sudo usermod -aG par-ssi a104533

# Exercício 3: 
tail -n 5 /etc/passwd
tail -n 5 /etc/group
# Comentário: Novos utilizadores aparecem no fim do ficheiro passwd e novos grupos no ficheiro group.

# Exercício 4: 
sudo chown a104266 braga.txt
ls -l braga.txt

# Exercício 5:
cat braga.txt

# Exercício 6 & 7:
su - a104266 -c 'echo "a104266 iniciado"' 
su - a104266 -c 'id;groups'
# Comentário: O comando mostra o uid/gid do utilizador e os grupos a que pertence (grupo-ssi, par-ssi).

# Exercício 8:
su - a104266 -c "cat '/home/vboxuser/semana3/braga.txt'"
# Comentário: Como alterámos o dono para a104266 no Ex 4, e o ficheiro tem permissão 400 (apenas dono),
# o a104266 consegue ler o ficheiro com sucesso.

# Exercício 9:
su - a104355 -c 'cd /home/vboxuser/semana3/dir2'
# Comentário: vai falhar
