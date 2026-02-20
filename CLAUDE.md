# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal dotfiles repository for a GPU-cluster-oriented ML/AI research workflow. Organized into topic directories, bootstrapped by `install.sh` (symlinks) or `setup.sh` (full Mac setup including Homebrew). Works on both macOS (laptop) and Linux Slurm clusters (no sudo required). Compatible with oh-my-zsh and oh-my-bash.

## Setup & Testing

```bash
# Full setup (Mac — installs Homebrew + packages + symlinks)
git clone https://github.com/ellisbrown/dotfiles.git ~/dotfiles
bash ~/dotfiles/setup.sh

# Minimal setup (clusters — symlinks only, no dependencies)
bash ~/dotfiles/install.sh

# Reload after changes
source ~/.aliases     # reload aliases directly
rsc                   # shortcut: re-sources ~/.zshrc or ~/.bashrc based on $SHELL
```

There is no build system or test suite. Changes are tested by re-sourcing.

## Directory Structure

```
~/dotfiles/
├── setup.sh                # Full Mac setup: brew + install.sh
├── install.sh              # Symlinks + shell RC configuration
├── Brewfile                # Declarative Mac packages (brew bundle)
├── shell/
│   ├── aliases             # Primary shell aliases/functions — main entry point
│   ├── inputrc             # Readline config (tab completion, history search)
│   └── localrc.example     # Template for ~/.localrc (machine-specific, not in git)
├── git/gitconfig           # Git aliases and settings (no credentials)
├── slurm/
│   ├── slurm_aliases.sh    # Router — sources the active cluster's config
│   ├── slurm_aliases.fsc.sh    # FSC cluster (H200 GPUs, h200_maestro_high QOS)
│   └── slurm_aliases.grogu.sh  # Grogu cluster (RTX 3090/6000, A5000/A6000)
├── vim/vimrc               # Vim configuration
├── tmux/tmux.conf          # Tmux config (mouse, 256-color, resurrect/continuum)
├── ghostty/config          # Ghostty terminal config (Mac only)
├── gdb/gdbinit             # GDB-GEF configuration
├── bin/wait.py             # Python utility: sleep with tqdm progress bar
└── REFERENCE.md            # Quick reference for all aliases and keybindings
```

Symlinks created by `install.sh`:

| Source | Target |
|---|---|
| `shell/aliases` | `~/.aliases` |
| `shell/inputrc` | `~/.inputrc` |
| `git/gitconfig` | `~/.gitconfig` |
| `vim/vimrc` | `~/.vimrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `gdb/gdbinit` | `~/.gdbinit` |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` (Mac only) |

## Architecture

**Source chain:** `~/.zshrc`/`~/.bashrc` → `$DOTFILES` export → `~/.aliases` → `shell/aliases` → `slurm/slurm_aliases.sh` → `slurm/slurm_aliases.fsc.sh` → `~/.localrc`

The `$DOTFILES` environment variable (set in shell RC files by `install.sh`) points to the repo root. All internal `source` commands use `$DOTFILES` for path resolution, defaulting to `$HOME/dotfiles`.

The `shell/aliases` file is the main entry point, organized in this order:
1. Shell helpers (`rsc`)
2. Core aliases (tmux, shell ops, nvidia)
3. **Modern CLI upgrades** — conditional aliases for eza, bat, fd, ripgrep that only activate if installed (`command -v` guard). Safe on clusters.
4. Git helpers (SSH/HTTPS toggle)
5. Rsync, conda/mamba aliases
6. **fzf integration** — Ctrl+R/Ctrl+T/Alt+C keybindings, conditional on fzf being installed. Uses fd as backend when available.
7. Python utilities
8. Slurm sourcing
9. `~/.localrc` (last — can override anything)

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
- **Conditional tool aliases**: Modern CLI replacements (eza, bat, fd, rg, fzf) are guarded by `command -v` checks. They activate automatically wherever the tool is installed and silently skip otherwise. This is the pattern to follow when adding new tool aliases.
- The `QOS` variable in `slurm_aliases.fsc.sh` (currently `h200_maestro_high`) is referenced by `sinteractive` and the `sdev-*` shortcuts. `sinteractive` defaults: 1 GPU, 48 CPUs/GPU, 80 GB mem/GPU, 1 hour.
- The `body()` helper (defined in both FSC and Grogu files) preserves header lines when piping sorted output — used extensively with `sinfo`/`squeue` pipes.
- `~/.localrc` (not in git) is sourced last for machine-specific overrides (API keys, project aliases, custom QOS). See `shell/localrc.example` for the template.
- `git/gitconfig` contains only QOL settings (aliases, rebase-on-pull, URL shorthands). Credentials and `user.name`/`user.email` belong in `~/.localrc` or `~/.gitconfig.local`.
- Platform-specific configs (e.g., Ghostty) are only symlinked on the relevant platform — `install.sh` handles this with `uname` detection.
- **Adding a new config**: Create a topic directory, add the config file, add a `link_file` line to `install.sh`, and update the symlink table above.
- See `REFERENCE.md` for a complete cheat sheet of all aliases, keybindings, and commands.
