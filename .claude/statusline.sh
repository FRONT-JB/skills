#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')

# Context window data
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# Build status line parts
parts=()

# Gray separator
sep=$'\e[0;90m│\e[0m'

# 1. Current time with emoji - first position
current_time=$(date +"%H:%M")
parts+=("🕐" $'\e[0;36m'"${current_time}"$'\e[0m')

# 2. Git branch (Green) with emoji
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    parts+=("$sep")
    parts+=("🌿")
    # Check if there are uncommitted changes
    if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || \
       ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
      parts+=($'\e[0;32m'"(${branch}*)"$'\e[0m')
    else
      parts+=($'\e[0;32m'"(${branch})"$'\e[0m')
    fi
  fi
fi

# 3. Progress bar (Green <50%, Yellow 50-75%, Red >75%) with emoji
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  # Calculate bar width (20 characters)
  bar_width=20
  filled=$(printf "%.0f" "$(echo "$used_pct * $bar_width / 100" | bc -l)")
  empty=$((bar_width - filled))

  # Color based on usage
  if (( $(echo "$used_pct > 75" | bc -l) )); then
    color=$'\e[0;31m' # red
  elif (( $(echo "$used_pct > 50" | bc -l) )); then
    color=$'\e[0;33m' # yellow
  else
    color=$'\e[0;32m' # green
  fi

  bar="${color}["
  [ $filled -gt 0 ] && bar+="$(printf '█%.0s' $(seq 1 $filled))"
  [ $empty -gt 0 ] && bar+="$(printf '░%.0s' $(seq 1 $empty))"
  bar+=$'\e[0m'

  parts+=("$sep")
  parts+=("📊" "$bar")

  # 3. Percentage context used (same color as progress bar)
  pct_formatted=$(printf "%.1f%%" "$used_pct")
  parts+=("${color}${pct_formatted}"$'\e[0m')
fi

# 4. Tokens (Magenta) with emoji
if [ "$context_size" -gt 0 ]; then
  total_used=$((total_input + total_output))
  parts+=("$sep")
  parts+=("💬")

  # Format with K suffix for readability
  if [ $total_used -ge 1000 ]; then
    used_k=$(echo "scale=1; $total_used / 1000" | bc)
    parts+=($'\e[0;35m'"${used_k}K"$'\e[0m')
  else
    parts+=($'\e[0;35m'"${total_used}"$'\e[0m')
  fi

  if [ $context_size -ge 1000 ]; then
    size_k=$(echo "scale=0; $context_size / 1000" | bc)
    parts+=($'\e[0;35m'"/ ${size_k}K"$'\e[0m')
  else
    parts+=($'\e[0;35m'"/ ${context_size}"$'\e[0m')
  fi
fi

# First line: custom info (branch, progress, tokens)
printf '%s\n' "${parts[*]}"

# Second and third lines: ccusage (split at 🔥)
ccusage_output=$(echo "$input" | ccusage statusline)
echo "$ccusage_output" | sed 's/ | 🔥/\
🔥/'
