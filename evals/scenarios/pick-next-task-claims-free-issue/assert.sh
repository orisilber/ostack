set -u
grep -q "Claimed DMI-41" "$OUT"                       || { echo "no claim announcement"; exit 1; }
grep -q "assign.*DMI-41\|DMI-41.*assign" "$CALLS_LOG" || { echo "never assigned DMI-41"; exit 1; }
! grep -q "assign.*DMI-4[23]" "$CALLS_LOG"            || { echo "touched a non-chosen ticket"; exit 1; }
grep -q "transition.*DMI-41" "$CALLS_LOG"             || { echo "did not transition"; exit 1; }
grep -qiE "feature|bugfix|fix/" <(cd "$WORK" && git branch --list | cat) \
	                                               || { echo "no branch created"; exit 1; }
(cd "$WORK" && git branch --list | grep -q "DMI-41")  || { echo "branch missing ticket key"; exit 1; }
