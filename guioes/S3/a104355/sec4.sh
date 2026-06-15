#!/bin/bash

# Dependência necessária
sudo apt install -y acl

# Exercício 1
getfacl porto.txt

# Exercício 2
sudo setfacl -m g:grupo-ssi:rw porto.txt

# Exercício 3
getfacl porto.txt
# Diferença: aparece uma entrada ACL para o grupo grupo-ssi com permissões rw.

# Exercício 4
su - a104355
echo "Teste ACL (G26)" >> /home/ssi/S3/porto.txt
cat /home/ssi/S3/porto.txt
# Resultado esperado: consegue escrever e ler o que escreveu graças à ACL para o grupo grupo-ssi.

exit
