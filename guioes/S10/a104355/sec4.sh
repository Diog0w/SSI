#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

cat > task7_example32b_apache.conf <<'EOF'
# Purpose: Do not set CSP policies
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example32a.com
    DirectoryIndex index.html
</VirtualHost>

# Purpose: Setting CSP policies in Apache configuration
# Mudanca feita: permitir scripts vindos de example60 e example70.
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example32b.com
    DirectoryIndex index.html
    Header set Content-Security-Policy " \
             default-src 'self'; \
             script-src 'self' *.example60.com *.example70.com \
           "
</VirtualHost>

# Purpose: Setting CSP policies in web applications
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example32c.com
    DirectoryIndex phpindex.php
</VirtualHost>

# Purpose: hosting Javascript files
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example60.com
</VirtualHost>

# Purpose: hosting Javascript files
<VirtualHost *:80>
    DocumentRoot /var/www/csp
    ServerName www.example70.com
</VirtualHost>
EOF

cat > task7_example32c_phpindex.php <<'EOF'
<?php
  $cspheader = "Content-Security-Policy:".
               "default-src 'self';".
               "script-src 'self' 'nonce-111-111-111' 'nonce-222-222-222' *.example60.com *.example70.com".
               "";
  header($cspheader);
?>

<?php include 'index.html';?>
EOF

cat > task7_expected_behaviour.txt <<'EOF'
Estado esperado com a configuracao oficial:

example32a:
- Areas 1, 2, 3, 4, 5 e 6 mostram OK
- O botao onclick executa JavaScript

example32b:
- Area 4 mostra OK
- Area 6 mostra OK
- Areas 1, 2, 3 e 5 falham
- O botao onclick e bloqueado

example32c:
- Area 1 mostra OK
- Area 4 mostra OK
- Area 6 mostra OK
- Areas 2, 3 e 5 falham
- O botao onclick e bloqueado

Depois das alteracoes propostas neste guia:

example32b modificado:
- Areas 4, 5 e 6 mostram OK

example32c modificado:
- Areas 1, 2, 4, 5 e 6 mostram OK
- Area 3 continua bloqueada
- O botao onclick continua bloqueado
EOF

printf 'Gerados: task7_example32b_apache.conf, task7_example32c_phpindex.php, task7_expected_behaviour.txt\n'
