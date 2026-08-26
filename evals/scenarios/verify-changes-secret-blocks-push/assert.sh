set -u
grep -q "VERIFY: FAIL" "$OUT"            || { echo "gate did not fail on secret"; exit 1; }
! grep -q -- "--- git push" "$CALLS_LOG" || { echo "pushed despite failed gate"; exit 1; }
grep -qiE "ESCALATION|secret|credential|AKIA" "$OUT" || { echo "no explanation of failure"; exit 1; }
