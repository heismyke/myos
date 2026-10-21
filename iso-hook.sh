#!/usr/bin/bash
set -euo pipefail

cat > /.buildstamp <<'EOF'
[Main]
Product=ZumaOS
Version=10
IsFinal=True
EOF
