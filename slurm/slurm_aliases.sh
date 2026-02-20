#!/bin/bash

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Set DOTFILES_CLUSTER in ~/.localrc to switch clusters (default: fsc)
cluster="${DOTFILES_CLUSTER:-fsc}"
source "$DOTFILES/slurm/slurm_aliases.${cluster}.sh"
