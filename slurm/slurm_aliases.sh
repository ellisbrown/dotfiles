#!/bin/bash

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Set DOTFILES_CLUSTER in ~/.localrc to switch clusters (default: fsc)
cluster="${DOTFILES_CLUSTER:-fsc}"
cluster_file="$DOTFILES/slurm/slurm_aliases.${cluster}.sh"

if [ -f "$cluster_file" ]; then
    source "$cluster_file"
else
    echo "Warning: unknown cluster '$cluster' (no file: $cluster_file)" >&2
fi
