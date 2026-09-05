#!/usr/bin/env bash
# Prints the path to a python3 with PyYAML importable. Uses the system
# python3 if it already has PyYAML (common in CI); otherwise creates a
# throwaway venv at evals/.venv and installs PyYAML there once, so we never
# touch the system/Homebrew Python (which may refuse global pip installs).
resolve_python() {
	if python3 -c "import yaml" >/dev/null 2>&1; then
		echo "python3"
		return
	fi

	local evals_dir venv
	evals_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	venv="$evals_dir/.venv"
	if [ ! -x "$venv/bin/python3" ]; then
		python3 -m venv "$venv" >&2 || return $?
	fi
	if ! "$venv/bin/python3" -c 'import yaml' >/dev/null 2>&1; then
		"$venv/bin/pip" install -q pyyaml >&2 || return $?
	fi
	echo "$venv/bin/python3"
}
