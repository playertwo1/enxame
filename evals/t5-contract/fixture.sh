set -e
cat > 'api.py' <<'FIXTURE_EOF'
def checkout(total_cents):
    return {"total_cents": total_cents}
FIXTURE_EOF
cat > 'ui.py' <<'FIXTURE_EOF'
def summary(resp):
    return f"Total: {resp['total_cents']}"
FIXTURE_EOF
