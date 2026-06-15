#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

cat > task1_payload.html <<'EOF'
<script>alert('XSS');</script>
EOF

cat > task2_payload.html <<'EOF'
<script>alert(document.cookie);</script>
EOF

printf 'Gerados: task1_payload.html, task2_payload.html\n'
