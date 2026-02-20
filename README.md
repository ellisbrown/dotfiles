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

On a fresh Mac, install Homebrew then use the Brewfile:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle
```

## Linux / Cluster Setup

Prerequisites (install what's available — none are strictly required):

```bash
# zsh (if you have sudo)
sudo apt install zsh

# oh-my-zsh
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# miniforge (conda/mamba without sudo)
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh
```

Then run the [Quick Start](#quick-start) steps above.

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
