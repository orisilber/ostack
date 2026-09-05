# --arg me USER --argjson last ID --argjson bots '["bot"]'
# --argjson humans_only true|false
[
  .[] | .id as $discussion | .notes[]
  | select((.system // false) | not)
  | select(.author.username != $me)
  | select((.id | tonumber) > $last)
  | select(($humans_only | not) or
      (.author.username as $author | ($bots | index($author)) == null))
  | {disc: $discussion, nid: (.id | tonumber), by: .author.username,
     text: .body, commit_id, position, created_at}
] | sort_by(.nid)
