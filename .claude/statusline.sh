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
# 갱신까지 남은 초 (epoch 우선, ISO 8601 대비)
_secs_left() {
  local now target raw="$1"; now=$(date +%s)
  if [[ "$raw" =~ ^[0-9]+$ ]]; then target=$raw
  else
    target=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$(echo "$raw" | sed -E 's/[.+Z].*$//')" +%s 2>/dev/null)
    [ -z "$target" ] && target=$now
  fi
  local d=$(( target - now )); [ "$d" -lt 0 ] && d=0; echo "$d"
}
# 5h 세션: "N시간M분" (0 단위 생략)
reltime_hm() {
  local d h m; d=$(_secs_left "$1"); h=$((d/3600)); m=$(((d%3600)/60))
  if   [ "$h" -gt 0 ] && [ "$m" -gt 0 ]; then echo "${h}시간${m}분"
  elif [ "$h" -gt 0 ]; then echo "${h}시간"
  else echo "${m}분"; fi
}
# 7d 주간: "N일 M시간" (0 단위 생략, 1시간 미만이면 분)
reltime_dh() {
  local d dd h m; d=$(_secs_left "$1"); dd=$((d/86400)); h=$(((d%86400)/3600)); m=$(((d%3600)/60))
  if   [ "$dd" -gt 0 ] && [ "$h" -gt 0 ]; then echo "${dd}일 ${h}시간"
  elif [ "$dd" -gt 0 ]; then echo "${dd}일"
  elif [ "$h" -gt 0 ]; then echo "${h}시간"
  else echo "${m}분"; fi
}

# ================= 모델 표기 (LINE 2에 포함) + branch 감지 =================
# context label: display_name에 이미 괄호 표기가 있으면 붙이지 않음(중복 방지)
if [[ "$model_name" == *"("* ]]; then ctx=""
elif [ "$context_size" -ge 1000000 ]; then ctx="1M"
elif [ "$context_size" -ge 1000 ]; then ctx="$((context_size/1000))K"
else ctx=""; fi

model_disp="${C_MODEL}${model_name}"
[ -n "$ctx" ] && model_disp+=" (${ctx})"
model_disp+="${R}"

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
    # 터미널 폭에 맞춰 표시폭(칸) 기준으로 자름. 앞 앵커(⌦ )+시각(약 9칸) 제외.
    cols=${COLUMNS:-120}
    pmax=$(( cols - 9 )); [ "$pmax" -lt 30 ] && pmax=30
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
l2="${C_TIME}⌦ ${now_t}${R}"
[ -n "$last_prompt" ] && l2+=" ${C_PROMPT}${last_prompt}${R}"

# ================= LINE 2: model · effort · thinking · version =================
leff="${C_STATUS}⌦ ${R}"
ef_body="${model_disp}"
[ -n "$effort_level" ] && ef_body+="${ef_body:+$sep}${C_LABEL}effort ${C_PROMPT}${effort_level}${R}"
if [ -n "$thinking_on" ]; then
  if [ "$thinking_on" = "true" ]; then th="on"; tc="$C_BRANCH"; else th="off"; tc="$C_OFF"; fi
  ef_body+="${ef_body:+$sep}${C_LABEL}thinking ${tc}${th}${R}"
fi
[ -n "$cc_version" ] && ef_body+="${ef_body:+$sep}${C_LABEL}v${cc_version}${R}"
leff+="$ef_body"

# ================= LINE 4: context gauge (원통 셀) =================
# 전 구간 동일 글리프 ⛁. 사용분=밝은 색(사용률), 여유분=옅은 회색.
# 색만으로 임계 표시: 초록(<40) · 앰버(40~75) · 빨강(75+). 기준점 마커(40/75)와 동일.
lctx=""
if [ "$context_size" -gt 0 ]; then
  ctx_used=$((total_input + total_output))
  ctx_pct=$(( ctx_used * 100 / context_size )); [ "$ctx_pct" -gt 100 ] && ctx_pct=100

  # 터미널 폭에 맞춰 셀 개수 산정(앵커/여백 ≈ 9칸 제외), 20~46칸으로 클램프
  ctx_cols=${COLUMNS:-120}
  # 5h/7d 남은시간+사용량을 뒤에 붙일 경우 폭 확보(약 44칸)
  rl_reserve=0; { [ -n "$fh_reset" ] || [ -n "$sd_reset" ]; } && rl_reserve=44
  bar_w=$(( ctx_cols - 9 - rl_reserve ))
  [ "$bar_w" -lt 20 ] && bar_w=20
  [ "$bar_w" -gt 46 ] && bar_w=46

  filled=$(( ctx_pct * bar_w / 100 ))
  [ "$ctx_pct" -gt 0 ] && [ "$filled" -lt 1 ] && filled=1
  # Dracula 팔레트 (게이지 전용 · 5h/7d 색은 rate_color 그대로)
  G_LOW=$'\e[0;38;2;80;250;123m'     # green  #50fa7b
  G_MID=$'\e[0;38;2;255;184;108m'    # amber  #ffb86c
  G_HI=$'\e[0;38;2;255;85;85m'       # red    #ff5555
  C_CTX_DIM=$'\e[0;38;2;78;70;62m'   # 여유 셀(옅은 회색)
  C_BOLD=$'\e[1m'                    # 퍼센트 볼드
  if   [ "$ctx_pct" -ge 75 ]; then ctx_col=$G_HI
  elif [ "$ctx_pct" -ge 40 ]; then ctx_col=$G_MID
  else                             ctx_col=$G_LOW; fi
  mc_amber=$G_MID                    # 40% 기준점
  mc_red=$G_HI                       # 75% 기준점
  m40=$(( 40 * bar_w / 100 ))
  m75=$(( 75 * bar_w / 100 ))

  bar=""
  for ((i=0; i<bar_w; i++)); do
    if   [ "$i" -lt "$filled" ]; then bar+="${ctx_col}${C_BOLD}⛁${R}"       # 사용분(밝게)
    elif [ "$i" -eq "$m40" ];   then bar+="${mc_amber}${C_BOLD}⛁${R}"      # 40% 기준점
    elif [ "$i" -eq "$m75" ];   then bar+="${mc_red}${C_BOLD}⛁${R}"        # 75% 기준점
    else                              bar+="${C_CTX_DIM}${C_BOLD}⛁${R}"; fi  # 여유(옅게)
  done

  lctx="${C_TOK}⌦ ${R}${bar} ${ctx_col}${C_BOLD}${ctx_pct}%${R}"
  # 세션(5h)·주간(7d) 리셋까지 남은시간 + 사용량(NN%) — 퍼센트 뒤에 옅게 표기
  rl=""
  if [ -n "$fh_reset" ]; then
    rl+="${C_LABEL}5h ${C_PROMPT}$(reltime_hm "$fh_reset")"
    [ -n "$fh_pct" ] && rl+="${C_LABEL}($(printf '%.0f' "$fh_pct")%)"
    rl+="${R}"
  fi
  if [ -n "$sd_reset" ]; then
    rl+="${rl:+$sep}${C_LABEL}7d ${C_PROMPT}$(reltime_dh "$sd_reset")"
    [ -n "$sd_pct" ] && rl+="${C_LABEL}($(printf '%.0f' "$sd_pct")%)"
    rl+="${R}"
  fi
  [ -n "$rl" ] && lctx+="${sep}${rl}"
fi

# ================= LINE 5: cwd(branch) · worktree =================
disp_cwd="${cwd/#$HOME/~}"
l3="${C_PATH}⌦ ${disp_cwd}"
[ -n "$branch" ] && l3+="(${branch}${star})"
l3+="${R}"
[ -n "$git_worktree" ] && l3+="${sep}${C_PATH}${git_worktree}${R}"

printf '%s\n' "$l2"
printf '%s\n' "$leff"
[ -n "$lctx" ] && printf '%s\n' "$lctx"
printf '%s\n' "$l3"
