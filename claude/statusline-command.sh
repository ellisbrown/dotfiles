#!/bin/bash

# Require jq and bc (graceful fallback if missing)
if ! command -v jq &>/dev/null || ! command -v bc &>/dev/null; then
    echo "$(basename "${PWD}") | Claude"
    exit 0
fi

input=$(cat)
reset="\033[0m"
dim="\033[2m"
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Cost and duration
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

# Format cost
cost_str=""
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
    cost_str=$(printf "$%.2f" "$cost_usd")
fi

# Format duration (ms -> human readable)
duration_str=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
    total_secs=$(( ${duration_ms%.*} / 1000 ))
    if [ "$total_secs" -ge 3600 ]; then
        hrs=$(( total_secs / 3600 ))
        mins=$(( (total_secs % 3600) / 60 ))
        duration_str="${hrs}h${mins}m"
    elif [ "$total_secs" -ge 60 ]; then
        mins=$(( total_secs / 60 ))
        secs=$(( total_secs % 60 ))
        duration_str="${mins}m${secs}s"
    else
        duration_str="${total_secs}s"
    fi
fi

# Combine cost + duration
stats=""
if [ -n "$cost_str" ] && [ -n "$duration_str" ]; then
    stats="${dim}${cost_str} ${duration_str}${reset}"
elif [ -n "$cost_str" ]; then
    stats="${dim}${cost_str}${reset}"
elif [ -n "$duration_str" ]; then
    stats="${dim}${duration_str}${reset}"
fi

# Current folder (basename only)
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
    folder=$(basename "$cwd")
else
    folder=$(basename "$PWD")
fi

# Git info (if in a repo)
git_branch=""
git_info=""
git_dir="${cwd:-$PWD}"
if git -C "$git_dir" rev-parse --is-inside-work-tree &>/dev/null; then
    git_branch=$(git -C "$git_dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$git_dir" rev-parse --short HEAD 2>/dev/null)

    # Check working tree status
    staged=$(git -C "$git_dir" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    unstaged=$(git -C "$git_dir" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$git_dir" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # Branch color: green if clean, yellow if dirty
    if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        branch_color="\033[33m"  # yellow — dirty
    else
        branch_color="\033[32m"  # green — clean
    fi

    # Build status indicators
    status_parts=""
    [ "$staged" -gt 0 ] && status_parts="${status_parts}\033[32m+${staged}${reset}"      # green for staged
    [ "$unstaged" -gt 0 ] && status_parts="${status_parts}\033[33m~${unstaged}${reset}"   # yellow for modified
    [ "$untracked" -gt 0 ] && status_parts="${status_parts}\033[31m?${untracked}${reset}" # red for untracked

    if [ -n "$status_parts" ]; then
        git_info="${branch_color}${git_branch}${reset} ${status_parts}"
    else
        git_info="${branch_color}${git_branch}${reset}"
    fi
fi

# If no messages yet, show folder + git + model only
if [ -z "$used_pct" ]; then
    if [ -n "$git_branch" ]; then
        printf "%s (%b) | %s\n" "$folder" "$git_info" "$model"
    else
        printf "%s | %s\n" "$folder" "$model"
    fi
    exit 0
fi

used_pct_int=$(printf "%.0f" "$used_pct")
bar_width=20
filled=$(printf "%.0f" "$(echo "$used_pct / 5" | bc -l)")
[ "$filled" -lt 0 ] && filled=0
[ "$filled" -gt "$bar_width" ] && filled=$bar_width
bar=""
for ((i=0; i<filled; i++)); do bar="${bar}█"; done
for ((i=filled; i<bar_width; i++)); do bar="${bar}░"; done
if [ "$used_pct_int" -ge 80 ]; then color="\033[31m"
elif [ "$used_pct_int" -ge 60 ]; then color="\033[33m"
else color="\033[32m"; fi

# Build final output: folder (git) | model | context | stats
if [ -n "$git_branch" ]; then
    printf "%s (%b) | %s | %b%s%b %d%%" "$folder" "$git_info" "$model" "$color" "$bar" "$reset" "$used_pct_int"
else
    printf "%s | %s | %b%s%b %d%%" "$folder" "$model" "$color" "$bar" "$reset" "$used_pct_int"
fi
if [ -n "$stats" ]; then
    printf " | %b" "$stats"
fi
