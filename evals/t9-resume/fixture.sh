set -e
cat > 'PLANO.md' <<'FIXTURE_EOF'
# Cadastro
- [x] CP1: criar save() em user.py
- [x] CP2: criar validate() em user.py, chamada por save()
- [ ] CP3: exigir email em validate()

FIXTURE_EOF
cat > 'user.py' <<'FIXTURE_EOF'
def save(user):
    return dict(user)
FIXTURE_EOF
