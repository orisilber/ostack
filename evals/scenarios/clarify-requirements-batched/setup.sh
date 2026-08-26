git init -q -b main
git config user.email dev@ostack.dev
git config user.name dev
mkdir -p web
echo "<div id=dashboard></div>" > web/index.html
echo "# fixture" > README.md
git add -A && git commit -qm init
cat > AGENTS.md <<'MD'
# Fixture repo

## Checks
- test: `echo ok`
MD
cat > "$PROMPT_FILE" <<'P'
Ticket WEB-77: "Improve the dashboard loading experience." There are no acceptance criteria. Clarify requirements per your skill, then stop and wait for answers.
P
