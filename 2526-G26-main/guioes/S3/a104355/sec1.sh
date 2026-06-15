#!/bin/bash

# Exercício 1
# Garantir que consigo escrever (se os ficheiros já existirem com permissões restritas)
rm -f lisboa.txt porto.txt braga.txt
echo "Lisboa é capital" > lisboa.txt
echo "Porto é cidade" > porto.txt
echo "Braga tem aura" > braga.txt

# Exercício 2
ls -l lisboa.txt

# Exercício 3
chmod 666 lisboa.txt
ls -l lisboa.txt

# Exercício 4
chmod 500 porto.txt
ls -l porto.txt

# Exercício 5
chmod 400 braga.txt
ls -l braga.txt

# Exercício 6
mkdir -p dir1 dir2
ls -ld dir1 dir2

# Exercício 7
chmod go-x dir2
ls -ld dir2
