#!/bin/bash

# Exercício 1
 rm -f lisboa.txt porto.txt braga.txt
 echo "Lisboa" > lisboa.txt
 echo "Porto" > porto.txt
 echo "Braga" > braga.txt
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
 mkdir dir1 dir2
 ls -ld dir1 dir2
# Exercício 7
 chmod go-x dir2
 ls -ld dir2
