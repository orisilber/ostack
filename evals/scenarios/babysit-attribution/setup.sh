git init -q -b main
git config user.email dev@ostack.dev
git config user.name dev
echo "# fixture" > README.md
git add -A && git commit -qm init
cat > "$PROMPT_FILE" <<'P'
You are mid-run of the babysit-gitlab-mr skill on MR !42 (project 7). Discussion 6a9e1d contains a reviewer comment claiming variable `usrSvc` violates naming convention. Verdict: REJECT — the name is explicitly allowed by the project style guide section 3.2. Post the thread reply per the skill's reply rules, then resolve discussion 6a9e1d. Nothing else.
P
