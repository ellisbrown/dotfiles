# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal dotfiles repository for a GPU-cluster-oriented ML/AI research workflow. Organized into topic directories, bootstrapped by `install.sh`, which symlinks config files and appends source lines into `~/.zshrc` and `~/.bashrc`. Works on both macOS (laptop) and Linux Slurm clusters (no sudo required).

## Setup & Testing

```bash
git clone https://github.com/ellisbrown/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
source ~/.zshrc  # or source ~/.bashrc
```

There is no build system, test suite, or package manager. Changes are tested by re-sourcing:

```bash
source ~/.aliases     # reload aliases directly
rsc                   # shortcut: re-sources ~/.zshrc or ~/.bashrc based on $SHELL
```

## Directory Structure

```
~/dotfiles/
├── install.sh              # Bootstrap: creates symlinks, configures shell RC files
├── shell/
│   ├── aliases             # Primary shell aliases/functions — main entry point
│   ├── inputrc             # Readline config (tab completion, history search)
│   └── localrc.example     # Template for ~/.localrc (machine-specific, not in git)
├── slurm/
│   ├── slurm_aliases.sh    # Router — sources the active cluster's config
│   ├── slurm_aliases.fsc.sh    # FSC cluster (H200 GPUs, h200_maestro_high QOS)
│   └── slurm_aliases.grogu.sh  # Grogu cluster (RTX 3090/6000, A5000/A6000)
├── vim/vimrc               # Vim configuration
├── tmux/tmux.conf          # Tmux config (mouse, 256-color, resurrect/continuum)
├── ghostty/config          # Ghostty terminal config (Mac only)
├── gdb/gdbinit             # GDB-GEF configuration
└── bin/wait.py             # Python utility: sleep with tqdm progress bar
```

Symlinks created by `install.sh`:

| Source | Target |
|---|---|
| `shell/aliases` | `~/.aliases` |
| `shell/inputrc` | `~/.inputrc` |
| `vim/vimrc` | `~/.vimrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `gdb/gdbinit` | `~/.gdbinit` |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` (Mac only) |

## Architecture

**Source chain:** `~/.zshrc`/`~/.bashrc` → `$DOTFILES` export → `~/.aliases` → `shell/aliases` → `slurm/slurm_aliases.sh` → `slurm/slurm_aliases.fsc.sh` → `~/.localrc`

The `$DOTFILES` environment variable (set in shell RC files by `install.sh`) points to the repo root. All internal `source` commands use `$DOTFILES` for path resolution, defaulting to `$HOME/dotfiles`.

The `shell/aliases` file is the main entry point. It defines general-purpose shell functions (tmux, git, rsync, conda/mamba, nvidia), sources Slurm aliases, and finally sources `~/.localrc` for machine-specific overrides.

The Slurm router (`slurm/slurm_aliases.sh`) sources exactly one cluster-specific file — toggle by commenting/uncommenting lines (currently FSC is active).

The FSC Slurm file (`slurm/slurm_aliases.fsc.sh`) is the largest component (~664 lines), organized into numbered sections:
1. Basic aliases (`si`, `sq`, `sqme`, `sqp`)
2. Interactive job management (`sinteractive` with `-g`, `-c`, `-m`, `-t`, `-q`, `-J` flags)
3. Cluster status & monitoring (`gpu-usage`, `cpu-usage`, `partition-usage`, `cluster-load`)
4. User & job analysis (`susers`, `my-usage`, `my-efficiency`, `stuck-jobs`)
5. Job management & control (`scancel-running`, `scancel-all`, `sjob`, `shistory`, `sdetails`)
6. Advanced monitoring (`snodes`, `gpu-utilization`, `qos-usage`)
7. Quick access watch aliases (`watch-jobs`, `watch-gpu`, `watch-users`)
9. SSH/dev session helpers (`sdev_tmux_ssh`, `sdev-gpu-x1`, `sdev-gpu-x4`, `sdev-gpu-x8`, `sdev-cpu-x24`, etc.)

## Key Conventions

- The `$DOTFILES` variable is used in all cross-file `source` commands. Defaults to `$HOME/dotfiles`.
- The `QOS` variable in `slurm_aliases.fsc.sh` (currently `h200_maestro_high`) is referenced by `sinteractive` and the `sdev-*` shortcuts. `sinteractive` defaults: 1 GPU, 48 CPUs/GPU, 80 GB mem/GPU, 1 hour.
- The `body()` helper (defined in both FSC and Grogu files) preserves header lines when piping sorted output — used extensively with `sinfo`/`squeue` pipes.
- `~/.localrc` (not in git) is sourced last for machine-specific overrides (API keys, project aliases, custom QOS). See `shell/localrc.example` for the template.
- Platform-specific configs (e.g., Ghostty) are only symlinked on the relevant platform — `install.sh` handles this with `uname` detection.
- Shell functions use POSIX-compatible patterns where possible but rely on bash/zsh features (e.g., `[[ ]]`, `read -r`) for interactive prompts.
