# dotfiles

Personal dotfiles for ML/AI research across macOS and Linux Slurm clusters.

## Quick Start

```bash
git clone https://github.com/ellisbrown/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
source ~/.zshrc  # or source ~/.bashrc
```

`install.sh` symlinks configs to the right places, detects your platform (Ghostty is Mac-only), and sets up shell RC files. Safe to run multiple times.

## What's Included

| Directory | What |
|---|---|
| `shell/` | Aliases, readline config, localrc template |
| `slurm/` | Slurm aliases for FSC and Grogu clusters |
| `vim/` | Vim configuration |
| `tmux/` | Tmux configuration |
| `ghostty/` | Ghostty terminal config (Mac) |
| `gdb/` | GDB-GEF config |
| `bin/` | Utility scripts |

## Mac Setup

On a fresh Mac, use `setup.sh` for a one-command setup (installs Homebrew, packages, and symlinks):

```bash
bash ~/dotfiles/setup.sh
```

Or do it manually:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle
```

## Linux / Cluster Setup

Clusters use bash (avoids zsh/Slurm compatibility issues). Optional prerequisites:

```bash
# miniforge (conda/mamba without sudo)
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh
```

Then run the [Quick Start](#quick-start) steps above (use `source ~/.bashrc` instead of `~/.zshrc`).

## Machine-Specific Config

Create `~/.localrc` for settings that shouldn't be in git (API keys, project aliases):

```bash
cp ~/dotfiles/shell/localrc.example ~/.localrc
# edit with your settings
```

This is sourced last, so it can override anything.

## Updating

```bash
cd ~/dotfiles && git pull
rsc   # reload shell
```
