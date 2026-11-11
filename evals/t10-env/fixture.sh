set -e
cat > 'run.log' <<'FIXTURE_EOF'
attempt 1
KeyError: 'DATABASE_URL'
  at config.py:3
attempt 2
KeyError: 'DATABASE_URL'
  at config.py:3
FIXTURE_EOF
cat > 'config.py' <<'FIXTURE_EOF'
import os

DATABASE_URL = os.environ['DATABASE_URL']
FIXTURE_EOF
