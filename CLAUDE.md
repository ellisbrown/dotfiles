# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal dotfiles repository (`~/dotfiles`) for a GPU-cluster-oriented ML/AI research workflow. All config files live at the top level (flat structure). The repo is cloned to `~/dotfiles` (or `~/config`) and bootstrapped via `aliases_init.sh`, which symlinks config files and appends source lines into `~/.zshrc` and `~/.bashrc`.

## Setup & Testing

```bash
git clone https://github.com/ellisbrown/dotfiles.git ~/dotfiles
bash ~/dotfiles/aliases_init.sh
source ~/.zshrc  # or source ~/.bashrc
```

There is no build system, test suite, or package manager. Changes are tested by re-sourcing:

```bash
source ~/dotfiles/aliases   # or: source ~/config/aliases
rsc                          # shortcut: re-sources ~/.zshrc or ~/.bashrc based on $SHELL
```

Symlinks created by `aliases_init.sh`: `~/.aliases -> ~/dotfiles/aliases`, `~/.tmux.conf -> ~/dotfiles/tmux.conf`. Additional manual symlink: `ln -s ~/dotfiles/gdbinit ~/.gdbinit`.

## Architecture

**Source chain:** `~/.zshrc`/`~/.bashrc` -> `aliases` -> `slurm_aliases.sh` -> `slurm_aliases.fsc.sh` (or `slurm_aliases.grogu.sh`)

The `aliases` file is the main entry point. It defines general-purpose shell functions (tmux, git, rsync, conda/mamba, nvidia) and at the end sources `slurm_aliases.sh`. The Slurm router (`slurm_aliases.sh`) sources exactly one cluster-specific file — toggle by commenting/uncommenting lines (currently FSC is active).

The FSC Slurm file (`slurm_aliases.fsc.sh`) is the largest component (~664 lines), organized into numbered sections:
1. Basic aliases (`si`, `sq`, `sqme`, `sqp`)
2. Interactive job management (`sinteractive` with `-g`, `-c`, `-m`, `-t`, `-q`, `-J` flags)
3. Cluster status & monitoring (`gpu-usage`, `cpu-usage`, `partition-usage`, `cluster-load`)
4. User & job analysis (`susers`, `my-usage`, `my-efficiency`, `stuck-jobs`)
5. Job management & control (`scancel-running`, `scancel-all`, `sjob`, `shistory`, `sdetails`)
6. Advanced monitoring (`snodes`, `gpu-utilization`, `qos-usage`)
7. Quick access watch aliases (`watch-jobs`, `watch-gpu`, `watch-users`)
9. SSH/dev session helpers (`sdev_tmux_ssh`, `sdev-gpu-x1`, `sdev-gpu-x4`, `sdev-gpu-x8`, `sdev-cpu-x24`, etc.)

Note: Section 8 does not exist (numbering jumps 7 -> 9 intentionally).

## Key Conventions

- The `QOS` variable in `slurm_aliases.fsc.sh` (currently `h200_maestro_high`) is referenced by `sinteractive` and the `sdev-*` shortcuts. `sinteractive` defaults: 1 GPU, 48 CPUs/GPU, 80 GB mem/GPU, 1 hour.
- The `body()` helper (defined in both FSC and Grogu files) preserves header lines when piping sorted output — used extensively with `sinfo`/`squeue` pipes.
- Shell functions use POSIX-compatible patterns where possible but rely on bash/zsh features (e.g., `[[ ]]`, `read -r`) for interactive prompts.
