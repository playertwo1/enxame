set -e
cat > 'pricing.py' <<'FIXTURE_EOF'
def total(unit_cents, quantity, discount_percent):
    return round(unit_cents * quantity * (100 - discount_percent) / 100)
FIXTURE_EOF
