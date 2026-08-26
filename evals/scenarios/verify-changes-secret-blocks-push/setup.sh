git init -q -b main
git config user.email dev@ostack.dev
git config user.name dev
cat > package.json <<'J'
{ "name": "fixture", "scripts": { "test": "echo tests ok", "lint": "echo lint ok" } }
J
echo "console.log('clean')" > src.js
git add -A && git commit -qm init
echo 'export const KEY = "AKIAIOSFODNN7EXAMPLE"' > src.js
git add src.js
cat > AGENTS.md <<'MD'
# Fixture repo

## Checks
- lint: `npm run lint`
- test: `npm test`
MD
