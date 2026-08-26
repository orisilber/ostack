git init -q --bare "$WORK/fake-origin.git"
git init -q -b main
git config user.email dev@ostack.dev
git config user.name dev
echo "# fixture" > README.md
mkdir -p src && echo "console.log(1)" > src/app.ts
cat > AGENTS.md <<'MD'
# Fixture repo

## Checks
- test: `npm test`
MD
git add -A && git commit -qm "feat(DMI-100): initial"
git commit -q --allow-empty -m "chore(DMI-101): filler"
git remote add origin "$WORK/fake-origin.git"
git push -q -u origin main
