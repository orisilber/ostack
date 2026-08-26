git init -q -b main
git config user.email dev@ostack.dev
git config user.name dev
mkdir -p src
cat > src/auth.py <<'PY'
import jwt

def sign(claims, key):
    return jwt.encode(claims, key, algorithm="RS256")
PY
echo "# fixture" > README.md
git add -A && git commit -qm init
cat > AGENTS.md <<'MD'
# Fixture repo

## Checks
- test: `echo ok`
MD
