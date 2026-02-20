# Quick Reference

Cheat sheet for all aliases and keybindings defined in this dotfiles repo.

## Shell

| Command | What it does |
|---|---|
| `rsc` | Reload shell config (sources `~/.zshrc` or `~/.bashrc`) |
| `sp` | Show disk usage of current directory, sorted by size |
| `spd` | Same as `sp` but includes dotfiles |
| `count` | Count files in current directory |
| `setcuda N` | Set `CUDA_VISIBLE_DEVICES=N` |
| `ns` | Watch `nvidia-smi` (refreshes every 0.5s) |
| `wait_for -H 1 -M 30` | Sleep with progress bar (hours/minutes/seconds) |

## Modern CLI Upgrades

These activate automatically if the tool is installed (via `brew bundle` on Mac or manual install on clusters). The original commands are still available via their full paths (e.g., `/bin/cat`, `/usr/bin/grep`).

| Alias | Tool | Replaces | Why |
|---|---|---|---|
| `ls` | eza | ls | Colored output, git status indicators |
| `ll` | eza -la --git | ls -la | Long listing with git status |
| `lt` | eza -laT --level=2 | tree | Tree view |
| `cat` | bat --paging=never | cat | Syntax highlighting |
| `catp` | bat | less | Syntax-highlighted pager |
| `ff` | fd | — | Simpler find, respects `.gitignore` |

## fzf (Fuzzy Finder)

| Keybinding | What it does |
|---|---|
| `Ctrl+R` | Fuzzy search shell history |
| `Ctrl+T` | Fuzzy find files (insert path at cursor) |
| `Alt+C` | Fuzzy cd into subdirectory |

## Tmux

| Command | What it does |
|---|---|
| `tn NAME` | New/attach to named session |
| `ta NAME` | Attach to existing session |
| `tl` | List sessions |
| `tk NAME` | Kill session |

**Tmux keybindings** (inside tmux):

| Key | What it does |
|---|---|
| `Ctrl+T` | Split vertical |
| `Ctrl+U` | Split horizontal |
| `Shift+Arrow` | Switch panes |
| `PageUp/Down` | Switch windows |
| `Alt+P` | Kill pane |
| `Alt+W` | Kill window |
| `Alt+S` | Kill session |
| `prefix r` | Reload tmux config |

## Git

### Aliases (use as `git <alias>`)

| Alias | Command | What it does |
|---|---|---|
| `git s` | `status -s` | Short status |
| `git d` | `diff` | Diff unstaged |
| `git ds` | `diff --staged` | Diff staged |
| `git lg` | `log --oneline --graph` | Pretty log (20 entries) |
| `git la` | `log --oneline --graph --all` | All branches log |
| `git co` | `checkout` | Checkout |
| `git cb` | `checkout -b` | Create branch |
| `git aa` | `add --all` | Stage everything |
| `git cm` | `commit -m` | Commit with message |
| `git ca` | `commit --amend` | Amend last commit |
| `git p` | `pull --rebase` | Pull with rebase |
| `git pf` | `push --force-with-lease` | Safe force push |
| `git br` | `branch --sort=-committerdate` | Branches by recent |
| `git fm TEXT` | search commit messages | Find commits by message |
| `git fc TEXT` | search code changes | Find commits by code |
| `git sl` | `stash list` | List stashes |
| `git sp` | `stash pop` | Pop stash |
| `git ss MSG` | `stash push -m` | Stash with message |

### Shell functions

| Command | What it does |
|---|---|
| `git-ssh` | Switch remote to SSH URL |
| `git-https` | Switch remote to HTTPS URL |

### URL shorthand

`git clone gh:user/repo` expands to `git clone git@github.com:user/repo`

### Settings

- `pull.rebase = true` — pull always rebases instead of merging
- `push.autoSetupRemote = true` — first push auto-creates upstream tracking
- `rebase.autoStash = true` — auto-stash dirty tree during rebase
- `merge.conflictStyle = diff3` — shows base, ours, and theirs in conflicts

## Rsync

| Command | What it does |
|---|---|
| `rscp SRC DST` | Copy with progress (`rsync -aP`) |
| `rsmv SRC DST` | Move with progress (deletes source after) |
| `rsnc SRC DST` | Fast network copy (no compression, preserves attrs) |

## Conda / Mamba

| Command | What it does |
|---|---|
| `ca ENV` | `conda activate ENV` |
| `ccf FILE` | Create env from YAML |
| `mcf FILE` | Create env from YAML (mamba) |
| `cuf FILE` | Update env from YAML |
| `muf FILE` | Update env from YAML (mamba) |

## Slurm (FSC Cluster)

### Queue & Info

| Command | What it does |
|---|---|
| `si` | Cluster node overview |
| `sq` | All jobs in queue |
| `sqme` | My jobs only (numbered) |
| `sqp PART` | Jobs in specific partition |

### Interactive Jobs

```bash
sinteractive              # 1 GPU, 48 CPUs, 80GB, 1 hour
sinteractive -g 4         # 4 GPUs
sinteractive -g 4 -t 8:00:00  # 4 GPUs, 8 hours
sinteractive -g 0 -c 16   # CPU-only, 16 cores
sinteractive -h            # full help
```

### Monitoring

| Command | What it does |
|---|---|
| `gpu-usage` | GPU cluster status + node breakdown |
| `cpu-usage` | CPU partition status |
| `partition-usage` | All partition usage |
| `cluster-load` | Comprehensive cluster summary |
| `my-usage` | Your current resource usage |
| `my-efficiency` | Your job CPU/memory efficiency |
| `susers` | All users sorted by GPU count |
| `stuck-jobs` | Jobs pending >60 min |

### Job Management

| Command | What it does |
|---|---|
| `sjob JOBID` | Show job details |
| `sdetails JOBID` | Extended job info |
| `shistory` | Recent job history |
| `scancel-running` | Cancel all your running jobs |
| `scancel-all` | Cancel all your jobs |

### Quick Dev Sessions

| Command | GPUs | CPUs | Mem | Time |
|---|---|---|---|---|
| `sdev-gpu-x1` | 1 | 16 | 186G | 7d |
| `sdev-gpu-x4` | 4 | 16 | 186G | 7d |
| `sdev-gpu-x8` | 8 | 16 | 186G | 7d |
| `sdev-cpu-x24` | 0 | 24 | 186G | 7d |

### Watch (auto-refreshing)

| Command | What it does |
|---|---|
| `watch-jobs` | Watch your job queue |
| `watch-gpu` | Watch GPU usage |
| `watch-users` | Watch user resource usage |
