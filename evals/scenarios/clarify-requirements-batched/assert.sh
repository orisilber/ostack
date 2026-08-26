set -u
n=$(grep -cE "^([0-9]+[.)]|- )" <<< "$(grep -E "\?" "$OUT")")
[ "${n:-0}" -ge 2 ]   || { echo "asked fewer than 2 questions"; exit 1; }
qs=$(grep -c "?" "$OUT"); [ "$qs" -le 12 ] || { echo "question dump (>12 marks)"; exit 1; }
! grep -q "No questions" "$OUT"       || { echo "claimed no questions on vague ticket"; exit 1; }
! grep -q -- "--- git add\|--- git commit" "$CALLS_LOG" || { echo "implemented instead of asking"; exit 1; }
