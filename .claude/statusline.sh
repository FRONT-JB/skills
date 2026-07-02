#!/bin/bash

# Add nvm node bin to PATH so ccusage is accessible
export NVM_DIR="$HOME/.nvm"
if [ -f "$NVM_DIR/alias/default" ]; then
  NODE_VERSION=$(cat "$NVM_DIR/alias/default")
  [[ "$NODE_VERSION" != v* ]] && NODE_VERSION="v${NODE_VERSION}"
  export PATH="$NVM_DIR/versions/node/${NODE_VERSION}/bin:$PATH"
fi

# Read JSON input from stdin
input=$(cat)

# ---- extract fields ----
# display_name에 "(1M context)" 같은 표기가 오면 " context" 제거 → "Opus 4.8 (1M)"
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"' | sed 's/ context//g')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

fh_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
fh_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
sd_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
sd_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# effort(추론 강도) · thinking(확장 사고) · version(CC 버전) · worktree
effort_level=$(echo "$input" | jq -r '.effort.level // empty')
thinking_on=$(echo "$input" | jq -r '.thinking.enabled | values | tostring')
cc_version=$(echo "$input" | jq -r '.version // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // .worktree.name // empty')

# ---- colors (Ember theme · bold faces) ----
C_MODEL=$'\e[1;38;2;255;158;100m'   # ember orange (모델 강조)
C_BRANCH=$'\e[0;38;2;195;232;141m'  # ember green (thinking on / 긍정)
C_TOK=$'\e[0;38;2;255;184;108m'     # ember amber (토큰)
C_TIME=$'\e[1;38;2;255;203;107m'    # ember gold (시각)
C_PROMPT=$'\e[0;38;2;236;224;210m'  # ember cream (프롬프트 · 값)
C_PATH=$'\e[0;38;2;224;104;90m'     # ember coral-red (경로)
C_STATUS=$'\e[1;38;2;247;140;108m'  # ember coral (세션 상태 앵커)
C_LABEL=$'\e[0;38;2;154;136;119m'   # ember warm gray (필드 라벨)
C_OFF=$'\e[0;38;2;154;136;119m'     # ember warm gray (thinking off 값)
C_SEP=$'\e[0;38;2;74;64;56m'        # ember warm dark (구분자)
R=$'\e[0m'
sep="${C_SEP} · ${R}"

# 사용률 기반 색 (낮음=초록 / 보통=노랑 / 높음=빨강)
rate_color() {
  local p=$1
  if (( $(echo "$p >= 80" | bc -l) )); then printf '\e[0;38;5;203m'      # red
  elif (( $(echo "$p >= 50" | bc -l) )); then printf '\e[0;38;5;221m'    # amber
  else printf '\e[0;38;2;195;232;141m'; fi                               # ember green (낮음)
}

# ---- helpers ----
fmt_tok() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then printf "%.1fM" "$(echo "scale=2; $n/1000000" | bc -l)"
  elif [ "$n" -ge 1000 ]; then printf "%dk" "$((n/1000))"
  else printf "%d" "$n"; fi
}
reltime() {
  local now d h m; now=$(date +%s); d=$(( $1 - now )); [ "$d" -lt 0 ] && d=0
  h=$((d/3600)); m=$(((d%3600)/60))
  if [ "$h" -gt 0 ]; then echo "${h}h ${m}m"; else echo "${m}m"; fi
}

# ================= LINE 1: model · branch · tokens · 5h · 7d =================
# context label: display_name에 이미 괄호 표기가 있으면 붙이지 않음(중복 방지)
if [[ "$model_name" == *"("* ]]; then ctx=""
elif [ "$context_size" -ge 1000000 ]; then ctx="1M"
elif [ "$context_size" -ge 1000 ]; then ctx="$((context_size/1000))K"
else ctx=""; fi

l1="${C_MODEL}٩(•◡•)۶  ${model_name}"
[ -n "$ctx" ] && l1+=" (${ctx})"
l1+="${R}"

# branch (★ if uncommitted changes)
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    star=""
    if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || \
       ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
      star="★"
    fi
  fi
fi

# tokens used / context size
if [ "$context_size" -gt 0 ]; then
  used=$((total_input + total_output))
  l1+="${sep}${C_TOK}$(fmt_tok "$used")/$(fmt_tok "$context_size")${R}"
fi

# 5h / 7d rate limits (사용률 색상 적용)
if [ -n "$fh_pct" ]; then
  fh_r=""; [ -n "$fh_reset" ] && fh_r=" ($(reltime "$fh_reset"))"
  l1+="${sep}$(rate_color "$fh_pct")5h $(printf '%.0f' "$fh_pct")%${fh_r}${R}"
fi
if [ -n "$sd_pct" ]; then
  sd_r=""; [ -n "$sd_reset" ] && sd_r=" ($(reltime "$sd_reset"))"
  l1+="${sep}$(rate_color "$sd_pct")7d $(printf '%.0f' "$sd_pct")%${sd_r}${R}"
fi

# ================= LINE 2: time + last prompt =================
now_t=$(date +"%H:%M")
last_prompt=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  last_prompt=$(tail -r "$transcript_path" 2>/dev/null \
    | jq -r 'select(.type=="user")
        | .message.content as $c
        | if ($c|type)=="string" then $c
          elif (($c|type)=="array") and ($c|any(.type=="image")) then ([$c[]|select(.type=="text")|.text]|join(" "))
          else empty end' 2>/dev/null \
    | sed 's/^[[:space:]]*//' \
    | grep -vE '^(<|\[|/|Caveat:)' \
    | head -1 | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
  if command -v perl > /dev/null 2>&1 && [ -n "$last_prompt" ]; then
    # 터미널 폭에 맞춰 표시폭(칸) 기준으로 자름. 앞 이모티콘+시각(약 18칸) 제외.
    cols=${COLUMNS:-120}
    pmax=$(( cols - 18 )); [ "$pmax" -lt 30 ] && pmax=30
    last_prompt=$(printf '%s' "$last_prompt" | PMAX=$pmax perl -CSD -ne '
      chomp; my $max=$ENV{PMAX}; my $w=0; my $out="";
      for my $c (split //) {
        my $cw = ($c =~ /[\x{1100}-\x{11FF}\x{2E80}-\x{9FFF}\x{AC00}-\x{D7A3}\x{F900}-\x{FAFF}\x{FF00}-\x{FF60}\x{3000}-\x{303F}]/) ? 2 : 1;
        last if $w + $cw > $max; $out .= $c; $w += $cw;
      }
      $out .= "\x{2026}" if length($out) < length($_);
      print $out;')
  fi
fi
l2="${C_TIME}٩( ᐛ )و  ${now_t}${R}"
[ -n "$last_prompt" ] && l2+=" ${C_PROMPT}${last_prompt}${R}"

# ================= LINE 3: effort · thinking · version =================
leff="${C_STATUS}( ◡̀_◡́)ᕤ  ${R}"
ef_body=""
[ -n "$effort_level" ] && ef_body+="${ef_body:+$sep}${C_LABEL}effort ${C_PROMPT}${effort_level}${R}"
if [ -n "$thinking_on" ]; then
  if [ "$thinking_on" = "true" ]; then th="on"; tc="$C_BRANCH"; else th="off"; tc="$C_OFF"; fi
  ef_body+="${ef_body:+$sep}${C_LABEL}thinking ${tc}${th}${R}"
fi
[ -n "$cc_version" ] && ef_body+="${ef_body:+$sep}${C_LABEL}v${cc_version}${R}"
leff+="$ef_body"

# ================= LINE 4: cwd(branch) · worktree =================
disp_cwd="${cwd/#$HOME/~}"
l3="${C_PATH}ᕕ( ᐛ )ᕗ  ${disp_cwd}"
[ -n "$branch" ] && l3+="(${branch}${star})"
l3+="${R}"
[ -n "$git_worktree" ] && l3+="${sep}${C_PATH}${git_worktree}${R}"

printf '%s\n' "$l2"
printf '%s\n' "$l1"
printf '%s\n' "$leff"
printf '%s\n' "$l3"
