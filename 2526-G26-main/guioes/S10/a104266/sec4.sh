#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat > "$SCRIPT_DIR/example32b.conf" <<'EOF'
# Sem politica CSP
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example32a.com
    DirectoryIndex index.html
</VirtualHost>

# Politica CSP no Apache
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example32b.com
    DirectoryIndex index.html
    Header set Content-Security-Policy " \
             default-src 'self'; \
             script-src 'self' *.example60.com *.example70.com \
           "
</VirtualHost>

# Politica CSP definida pela aplicacao
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example32c.com
    DirectoryIndex phpindex.php
</VirtualHost>

<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example60.com
</VirtualHost>

<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example70.com
</VirtualHost>
EOF

cat > "$SCRIPT_DIR/phpindex.php" <<'EOF'
<?php
  $cspheader = "Content-Security-Policy:" .
               "default-src 'self';" .
               "script-src 'self' 'nonce-111-111-111' 'nonce-222-222-222' *.example60.com *.example70.com";
  header($cspheader);
?>

<?php include 'index.html'; ?>
EOF

cat > "$SCRIPT_DIR/task7_notas.txt" <<'EOF'
Resumo Task 7

Configuracao original:
- example32a: sem CSP, tudo permitido
- example32b: self + example70, inline bloqueado
- example32c: self + example70 + nonce 111-111-111

Depois das mudancas:
- example32b passa a aceitar tambem scripts de example60
- example32c passa a aceitar example60 e o nonce 222-222-222

Efeito pratico:
- Area 5 passa a funcionar em b e c
- Area 2 passa a funcionar em c
- Area 3 continua bloqueada
- onclick continua bloqueado
EOF

printf 'Criados: example32b.conf, phpindex.php e task7_notas.txt\n'
