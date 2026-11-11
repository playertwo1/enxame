set -e
cat > 'PLANO.md' <<'FIXTURE_EOF'
# Relatório de descontos
1. Em report.py, some orders.discount_cents por mês.
2. Aplique a regra de desconto progressivo acordada.

FIXTURE_EOF
cat > 'schema.sql' <<'FIXTURE_EOF'
CREATE TABLE orders (id INTEGER PRIMARY KEY, total_cents INTEGER NOT NULL, created_at TEXT NOT NULL);
FIXTURE_EOF
cat > 'report.py' <<'FIXTURE_EOF'
def monthly_report(rows):
    return {}
FIXTURE_EOF
