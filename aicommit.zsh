function aicommit() {
  API_URL="http://localhost:11434"
  MODEL="llama3.1:8b"
  API_KEY=$OPENAI_API_KEY
  USER_PROMPT="Write a commit message for the following diff:"
  SYSTEM_PROMPT="You are a developer who writes a commit message. You must only generate the commit message. Do not output quotes. Do not write feat:, fix:, or similar prefixes. Write in lowercase and be short. Write in one line."

  curl -sI $API_URL -o /dev/null
  if [ $? -ne 0 ]; then
    echo "Ollama is not running"
    return
  fi

  ESCAPED_DIFF=$(printf '%s' "$(git diff --cached)" | jq -R)
  if [[ -z $ESCAPED_DIFF ]]; then
    echo "No files added"
    return
  fi

  JSON_PAYLOAD=$(jq -n --arg model "$MODEL" --arg user_prompt "$USER_PROMPT" --arg system_prompt "$SYSTEM_PROMPT" --arg diff "$ESCAPED_DIFF" '{"model": $model, "stream": false, "messages": [{"role": "system", "content": "\($system_prompt)"}, {"role": "user", "content": "\($user_prompt) \($diff)"}]}')
  OUTPUT=$(curl -s -XPOST $API_URL/v1/chat/completions -H "authorization: Bearer $API_KEY" -H "content-type: application/json" --data-binary $JSON_PAYLOAD | jq '.choices[0].message.content')
  print -z "git commit -m $OUTPUT"
}
