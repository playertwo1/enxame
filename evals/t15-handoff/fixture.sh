set -e
cat > 'RULES.md' <<'FIXTURE_EOF'
Cupons: valor em centavos inteiros. Não acumulam: vale só o maior. Total nunca fica negativo.
FIXTURE_EOF
cat > 'cart.py' <<'FIXTURE_EOF'
def total(items):
    return sum(i['cents'] for i in items)
FIXTURE_EOF
