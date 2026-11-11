set -e
cat > 'MIGRACAO.md' <<'FIXTURE_EOF'
# Migração de valores
Converter payments.amount (float) para amount_cents (inteiro) em produção.
1. Adicionar coluna amount_cents.
2. Preencher com round(amount*100).
3. Remover amount.

FIXTURE_EOF
