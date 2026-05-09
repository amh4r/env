#!/bin/bash
export PATH="$HOME/.nix-profile/bin:$PATH"
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | round')
echo "[$model] ${pct}% context"
