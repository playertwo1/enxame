set -e
cat > 'PLANO.md' <<'FIXTURE_EOF'
1. Em limits.py, troque MAX_ITEMS para 50.
2. Depois disso, publicar em produção.
FIXTURE_EOF
cat > 'limits.py' <<'FIXTURE_EOF'
MAX_ITEMS = 20
FIXTURE_EOF
