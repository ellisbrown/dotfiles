#!/usr/bin/env bash
# shellcheck disable=SC2034
# =============================================================================
#  ref — Terminal quick reference for dotfiles aliases and commands
# =============================================================================
#  Usage:
#    ref              List all topics
#    ref <topic>      Show commands for a topic (e.g., ref git)
#    ref <query>      Search all commands for a keyword (e.g., ref scancel)
#
#  Topics: shell, cli, fzf, tmux, git, rsync, conda, slurm, python
# =============================================================================

# --- Colors (prefixed to avoid polluting namespace) ---
_ref_bold='\033[1m'
_ref_dim='\033[2m'
_ref_green='\033[32m'
_ref_cyan='\033[36m'
_ref_yellow='\033[33m'
_ref_magenta='\033[35m'
_ref_reset='\033[0m'

# --- Formatting helpers ---

_ref_header() {
    printf "\n${_ref_bold}${_ref_cyan}  %s${_ref_reset}\n" "$1"
    printf "  %s\n" "$(printf '%*s' "${#1}" '' | tr ' ' '─')"
}

_ref_cmd() {
    printf "  ${_ref_green}%-28s${_ref_reset} %s\n" "$1" "$2"
}

_ref_tip() {
    printf "  ${_ref_dim}${_ref_yellow}TIP:${_ref_reset} ${_ref_dim}%s${_ref_reset}\n" "$1"
}

_ref_example() {
    printf "  ${_ref_dim}  \$ %s${_ref_reset}\n" "$1"
}

_ref_section() {
    printf "\n  ${_ref_magenta}%s${_ref_reset}\n" "$1"
}

# --- Main function ---

function ref {
    local topic
    if [ $# -eq 0 ]; then
        printf "\n${_ref_bold}${_ref_cyan}  Dotfiles Quick Reference${_ref_reset}\n"
        printf "  %s\n\n" "─────────────────────────"
        _ref_cmd "ref shell" "Shell helpers, disk usage, nvidia"
        _ref_cmd "ref cli" "Modern CLI upgrades (eza, bat, fd, rg)"
        _ref_cmd "ref fzf" "Fuzzy finder keybindings"
        _ref_cmd "ref tmux" "Tmux aliases and keybindings"
        _ref_cmd "ref git" "Git aliases, functions, settings"
        _ref_cmd "ref rsync" "Rsync copy/move shortcuts"
        _ref_cmd "ref conda" "Conda/mamba environment commands"
        _ref_cmd "ref slurm" "Slurm job management (FSC cluster)"
        _ref_cmd "ref python" "Python utilities"
        printf "\n  ${_ref_dim}Or search: ${_ref_green}ref <keyword>${_ref_reset}\n\n"
        return 0
    fi

    topic="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

    case "$topic" in

    shell)
        _ref_header "Shell Helpers"
        _ref_cmd "rsc" "Reload shell config (sources ~/.zshrc or ~/.bashrc)"
        _ref_example "rsc"
        _ref_cmd "sp" "Show disk usage of current dir, sorted by size"
        _ref_cmd "spd" "Same as sp but includes dotfiles"
        _ref_cmd "susp" "Same as sp with sudo"
        _ref_cmd "count" "Count files in current directory"
        _ref_cmd "countall" "Count all files recursively"
        _ref_cmd "kys" "Kill all processes of current user (with confirmation)"
        _ref_cmd "sv" "Launch snakeviz profiler on port 8081"

        _ref_section "NVIDIA / CUDA"
        _ref_cmd "ns" "Watch nvidia-smi (refreshes every 0.5s)"
        _ref_cmd "setcuda N" "Set CUDA_VISIBLE_DEVICES=N"
        _ref_example "setcuda 0,1"
        ;;

    cli|tools)
        _ref_header "Modern CLI Upgrades"
        _ref_tip "These activate automatically if the tool is installed."
        _ref_tip "Original commands still available at /bin/cat, /usr/bin/grep, etc."
        printf "\n"
        _ref_cmd "ls" "eza — colored output, git status indicators"
        _ref_cmd "ll" "eza -la --git — long listing with git status"
        _ref_cmd "lt" "eza -laT --level=2 — tree view (2 levels)"
        _ref_cmd "cat" "bat --paging=never — syntax highlighting"
        _ref_cmd "catp" "bat — syntax-highlighted pager"
        _ref_cmd "ff" "fd — simpler find, respects .gitignore"
        _ref_cmd "rgrep" "rg — faster grep, respects .gitignore"
        _ref_tip "Install on Mac: brew bundle (uses Brewfile)"
        ;;

    fzf|fuzzy)
        _ref_header "fzf (Fuzzy Finder)"
        _ref_tip "Requires fzf installed. Uses fd as backend when available."
        printf "\n"
        _ref_cmd "Ctrl+R" "Fuzzy search shell history"
        _ref_cmd "Ctrl+T" "Fuzzy find files (insert path at cursor)"
        _ref_cmd "Alt+C" "Fuzzy cd into subdirectory"
        _ref_tip "Alt keys need macos-option-as-alt in Ghostty/terminal settings."
        ;;

    tmux)
        _ref_header "Tmux Aliases"
        _ref_cmd "tn NAME" "New/attach to named session"
        _ref_cmd "ta NAME" "Attach to existing session"
        _ref_cmd "tl" "List sessions"
        _ref_cmd "tk NAME" "Kill session"
        _ref_example "tn dev"

        _ref_section "Keybindings (prefix: Ctrl+A)"
        _ref_cmd "Ctrl+B" "Split vertical (direct, no prefix)"
        _ref_cmd "Ctrl+U" "Split horizontal (direct, no prefix)"
        _ref_cmd "Shift+Arrow" "Switch panes"
        _ref_cmd "PageUp/Down" "Switch windows"
        _ref_cmd "Alt+P" "Kill pane"
        _ref_cmd "Alt+W" "Kill window"
        _ref_cmd "Alt+S" "Kill session"
        _ref_cmd "prefix r" "Reload tmux config"
        _ref_cmd "prefix P" "Save scrollback to file"
        _ref_tip "Alt keys need macos-option-as-alt in Ghostty/terminal settings."
        ;;

    git)
        _ref_header "Git Aliases (git <alias>)"
        _ref_cmd "git s" "status -s — short status"
        _ref_cmd "git d" "diff — diff unstaged"
        _ref_cmd "git ds" "diff --staged — diff staged"
        _ref_cmd "git lg" "log --oneline --graph — pretty log (20 entries)"
        _ref_cmd "git la" "log --oneline --graph --all — all branches"
        _ref_cmd "git co" "checkout"
        _ref_cmd "git cb" "checkout -b — create branch"
        _ref_cmd "git aa" "add --all — stage everything"
        _ref_cmd "git cm" "commit -m — commit with message"
        _ref_cmd "git ca" "commit --amend — amend last commit"
        _ref_cmd "git p" "pull --rebase"
        _ref_cmd "git pf" "push --force-with-lease — safe force push"
        _ref_cmd "git br" "branch --sort=-committerdate — branches by recent"
        _ref_cmd "git fm TEXT" "Search commits by message"
        _ref_cmd "git fc TEXT" "Search commits by code change"
        _ref_cmd "git sl" "stash list"
        _ref_cmd "git sp" "stash pop"
        _ref_cmd "git ss MSG" "stash push -m — stash with message"

        _ref_section "Shell Functions"
        _ref_cmd "git-ssh" "Switch remote to SSH URL"
        _ref_cmd "git-https" "Switch remote to HTTPS URL"

        _ref_section "URL Shorthand"
        _ref_cmd "gh:user/repo" "Expands to git@github.com:user/repo"
        _ref_example "git clone gh:ellisbrown/dotfiles"

        _ref_section "Settings"
        _ref_cmd "pull.rebase" "Pull always rebases instead of merging"
        _ref_cmd "push.autoSetupRemote" "First push auto-creates upstream tracking"
        _ref_cmd "rebase.autoStash" "Auto-stash dirty tree during rebase"
        _ref_cmd "merge.conflictStyle" "diff3 — shows base, ours, theirs in conflicts"
        ;;

    rsync)
        _ref_header "Rsync"
        _ref_cmd "rscp SRC DST" "Copy with progress (rsync -aP)"
        _ref_cmd "rsmv SRC DST" "Move with progress (deletes source after)"
        _ref_cmd "rsnc SRC DST" "Fast network copy (no compression, preserves attrs)"
        _ref_example "rscp ./data/ user@cluster:~/data/"
        _ref_example "rsnc user@cluster:~/results/ ./results/"
        ;;

    conda|mamba)
        _ref_header "Conda / Mamba"
        _ref_cmd "ca ENV" "conda activate ENV"
        _ref_cmd "ccf FILE" "Create env from YAML (conda)"
        _ref_cmd "mcf FILE" "Create env from YAML (mamba — faster)"
        _ref_cmd "cuf FILE" "Update env from YAML (conda)"
        _ref_cmd "muf FILE" "Update env from YAML (mamba)"
        _ref_example "ca myenv"
        _ref_example "mcf environment.yml"
        ;;

    slurm)
        _ref_header "Slurm (FSC Cluster)"

        _ref_section "Queue & Info"
        _ref_cmd "si" "Cluster node overview"
        _ref_cmd "sq" "All jobs in queue"
        _ref_cmd "sqme" "My jobs only (numbered)"
        _ref_cmd "sqp PARTITION" "Jobs in specific partition"

        _ref_section "Interactive Jobs"
        _ref_cmd "sinteractive" "Interactive shell with GPU/CPU resources"
        _ref_cmd "  -g N" "Number of GPUs (default: 1)"
        _ref_cmd "  -c N" "CPUs per GPU (default: 48)"
        _ref_cmd "  -m N" "Memory in GB per GPU (default: 80)"
        _ref_cmd "  -t TIME" "Time limit (default: 1:00:00)"
        _ref_cmd "  -q QOS" "QOS (default: h200_maestro_high)"
        _ref_cmd "  -J NAME" "Job name"
        _ref_cmd "  -h" "Show full help"
        _ref_example "sinteractive -g 4 -t 8:00:00"
        _ref_example "sinteractive -g 0 -c 16           # CPU-only"

        _ref_section "Monitoring"
        _ref_cmd "gpu-usage" "GPU cluster status + node breakdown"
        _ref_cmd "cpu-usage" "CPU partition status"
        _ref_cmd "partition-usage" "All partition usage"
        _ref_cmd "cluster-load" "Comprehensive cluster summary"
        _ref_cmd "my-usage" "Your current resource usage"
        _ref_cmd "my-efficiency" "Your job CPU/memory efficiency"
        _ref_cmd "susers" "All users sorted by GPU count"
        _ref_cmd "stuck-jobs" "Jobs pending >60 min"

        _ref_section "Job Management"
        _ref_cmd "sjob JOBID" "Show job details"
        _ref_cmd "sdetails JOBID" "Extended job info"
        _ref_cmd "shistory" "Recent job history"
        _ref_cmd "scancel-running" "Cancel all your running jobs"
        _ref_cmd "scancel-all" "Cancel all your jobs"

        _ref_section "Advanced Monitoring"
        _ref_cmd "snodes" "Detailed node status"
        _ref_cmd "gpu-utilization" "GPU utilization across nodes"
        _ref_cmd "qos-usage" "QOS usage breakdown"

        _ref_section "Quick Dev Sessions"
        _ref_cmd "sdev-gpu-x1" "1 GPU, 16 CPUs, 186G mem, 7 days"
        _ref_cmd "sdev-gpu-x4" "4 GPUs, 16 CPUs, 186G mem, 7 days"
        _ref_cmd "sdev-gpu-x8" "8 GPUs, 16 CPUs, 186G mem, 7 days"
        _ref_cmd "sdev-cpu-x24" "0 GPUs, 24 CPUs, 186G mem, 7 days"
        _ref_tip "sdev-* sessions auto-attach via tmux."

        _ref_section "Watch (auto-refreshing)"
        _ref_cmd "watch-jobs" "Watch your job queue"
        _ref_cmd "watch-gpu" "Watch GPU usage"
        _ref_cmd "watch-users" "Watch user resource usage"
        ;;

    python|py)
        _ref_header "Python Utilities"
        _ref_cmd "wait_for" "Sleep with tqdm progress bar"
        _ref_cmd "  -H N" "Hours"
        _ref_cmd "  -M N" "Minutes"
        _ref_cmd "  -S N" "Seconds"
        _ref_example "wait_for -H 1 -M 30"
        _ref_example "wait_for -M 5"
        ;;

    *)
        _ref_search "$topic"
        ;;
    esac
    printf "\n"
}

# --- Search helper ---
# Searches a pipe-delimited index of all commands.
# Format: topic|command|description

function _ref_search {
    local query="$1"
    local found=0

    # Pipe-delimited search index: topic|command|description
    local index
    read -r -d '' index <<'SEARCH_INDEX'
shell|rsc|Reload shell config (sources ~/.zshrc or ~/.bashrc)
shell|sp|Show disk usage of current dir, sorted by size
shell|spd|Same as sp but includes dotfiles
shell|susp|Same as sp with sudo
shell|count|Count files in current directory
shell|countall|Count all files recursively
shell|kys|Kill all processes of current user (with confirmation)
shell|sv|Launch snakeviz profiler on port 8081
shell|ns|Watch nvidia-smi (refreshes every 0.5s)
shell|setcuda N|Set CUDA_VISIBLE_DEVICES=N
cli|ls|eza — colored output, git status indicators
cli|ll|eza -la --git — long listing with git status
cli|lt|eza -laT --level=2 — tree view
cli|cat|bat --paging=never — syntax highlighting
cli|catp|bat — syntax-highlighted pager
cli|ff|fd — simpler find, respects .gitignore
cli|rgrep|rg — faster grep, respects .gitignore
fzf|Ctrl+R|Fuzzy search shell history
fzf|Ctrl+T|Fuzzy find files (insert path at cursor)
fzf|Alt+C|Fuzzy cd into subdirectory
tmux|tn NAME|New/attach to named tmux session
tmux|ta NAME|Attach to existing tmux session
tmux|tl|List tmux sessions
tmux|tk NAME|Kill tmux session
tmux|Ctrl+B|Split vertical (direct, no prefix)
tmux|Ctrl+U|Split horizontal (direct, no prefix)
tmux|Shift+Arrow|Switch panes
tmux|PageUp/Down|Switch windows
tmux|Alt+P|Kill pane
tmux|Alt+W|Kill window
tmux|Alt+S|Kill session
tmux|prefix r|Reload tmux config
git|git s|status -s — short status
git|git d|diff — diff unstaged
git|git ds|diff --staged — diff staged
git|git lg|log --oneline --graph — pretty log
git|git la|log --oneline --graph --all — all branches
git|git co|checkout
git|git cb|checkout -b — create branch
git|git aa|add --all — stage everything
git|git cm|commit -m — commit with message
git|git ca|commit --amend — amend last commit
git|git p|pull --rebase
git|git pf|push --force-with-lease — safe force push
git|git br|branch --sort=-committerdate — branches by recent
git|git fm TEXT|Search commits by message
git|git fc TEXT|Search commits by code change
git|git sl|stash list
git|git sp|stash pop
git|git ss MSG|stash push -m — stash with message
git|git-ssh|Switch remote to SSH URL
git|git-https|Switch remote to HTTPS URL
rsync|rscp SRC DST|Copy with progress (rsync -aP)
rsync|rsmv SRC DST|Move with progress (deletes source after)
rsync|rsnc SRC DST|Fast network copy (no compression)
conda|ca ENV|conda activate ENV
conda|ccf FILE|Create env from YAML (conda)
conda|mcf FILE|Create env from YAML (mamba)
conda|cuf FILE|Update env from YAML (conda)
conda|muf FILE|Update env from YAML (mamba)
slurm|si|Cluster node overview
slurm|sq|All jobs in queue
slurm|sqme|My jobs only (numbered)
slurm|sqp PARTITION|Jobs in specific partition
slurm|sinteractive|Interactive shell with GPU/CPU resources
slurm|gpu-usage|GPU cluster status + node breakdown
slurm|cpu-usage|CPU partition status
slurm|partition-usage|All partition usage
slurm|cluster-load|Comprehensive cluster summary
slurm|my-usage|Your current resource usage
slurm|my-efficiency|Your job CPU/memory efficiency
slurm|susers|All users sorted by GPU count
slurm|stuck-jobs|Jobs pending >60 min
slurm|sjob JOBID|Show job details
slurm|sdetails JOBID|Extended job info
slurm|shistory|Recent job history
slurm|scancel-running|Cancel all your running jobs
slurm|scancel-all|Cancel all your jobs
slurm|snodes|Detailed node status
slurm|gpu-utilization|GPU utilization across nodes
slurm|qos-usage|QOS usage breakdown
slurm|sdev-gpu-x1|1 GPU, 16 CPUs, 186G mem, 7 days
slurm|sdev-gpu-x4|4 GPUs, 16 CPUs, 186G mem, 7 days
slurm|sdev-gpu-x8|8 GPUs, 16 CPUs, 186G mem, 7 days
slurm|sdev-cpu-x24|0 GPUs, 24 CPUs, 186G mem, 7 days
slurm|watch-jobs|Watch your job queue
slurm|watch-gpu|Watch GPU usage
slurm|watch-users|Watch user resource usage
python|wait_for|Sleep with tqdm progress bar (-H hours, -M min, -S sec)
SEARCH_INDEX

    printf "\n${_ref_bold}${_ref_cyan}  Search: ${_ref_reset}${_ref_bold}%s${_ref_reset}\n" "$query"
    printf "  %s\n" "──────────────────────────"

    # Read line by line to stay portable (no arrays)
    while IFS='|' read -r stopic scmd sdesc; do
        # Skip empty lines
        [ -z "$stopic" ] && continue
        # Case-insensitive match against command and description
        if printf '%s %s' "$scmd" "$sdesc" | grep -qi "$query"; then
            printf "  ${_ref_dim}[%-6s]${_ref_reset} ${_ref_green}%-28s${_ref_reset} %s\n" "$stopic" "$scmd" "$sdesc"
            found=$((found + 1))
        fi
    done <<EOF
$index
EOF

    if [ "$found" -eq 0 ]; then
        printf "  ${_ref_dim}No matches found. Try: ref (to list topics)${_ref_reset}\n"
    else
        printf "\n  ${_ref_dim}%d match(es). Run ${_ref_green}ref <topic>${_ref_dim} for full details.${_ref_reset}\n" "$found"
    fi
}
