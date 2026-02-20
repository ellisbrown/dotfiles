#!/bin/bash
#
# ==============================================================================
#  Slurm Aliases and Functions for the FSC Cluster
# ==============================================================================
#
# Instructions:
# 1. Paste this entire block into the end of your ~/.bashrc or ~/.zshrc file.
# 2. Reload your shell configuration by running: source ~/.bashrc or source ~/.zshrc

# --- Helper function to keep header on sorted output ---
# This reads the first line (header), prints it, and then passes the rest
# of the output to the specified command (e.g., sort).
body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}

# ==============================================================================
#  QUICK REFERENCE - Most Used Commands
# ==============================================================================
# gpu-usage          - Show GPU cluster status and node breakdown
# my-usage           - Show your current resource usage summary
# susers             - Show user resource usage (sorted by GPU count)
# sinteractive       - Get interactive shell with GPU/CPU resources
# stuck-jobs         - Find jobs pending for more than 60 minutes
# partition-usage    - Show usage across all partitions
# cluster-load       - Comprehensive cluster load summary

# ==============================================================================
#  Section 1: Basic Aliases (Quick Commands)
# ==============================================================================

# General, sorted, node-based view of the cluster.
alias si="sinfo --Node -o '%15P %15N %12S %C %10m %10f %30G' | body sort"

# Show only the GPU 'learn' partition, focusing on GPU resources.
alias sigpu="sinfo -N -p learn -o '%25N %12S %C %10m %10f %G'"

# Show only the 'cpu' partition.
alias sicpu="sinfo -N -p cpu -o '%25N %12S %C %10m %10f'"

# A wide, sorted view of all jobs in the queue with GPU count.
alias sq="squeue -o '%.7i %.12u %.10P %.25j %.4t %.10M %.6D %.10b %S %R' --sort=-p"

# Show only my jobs, with a line number, CPU count, and GPU count.
alias sqme="squeue -u $USER -o '%.7i %.12P %.25j %.4t %.10M %.6D %.4C %.10b %R' | nl -v 0"

QOS=h200_maestro_high

# Function to show jobs in a specific partition. Usage: sqp <partition_name>
sqp() {
    if [ -z "$1" ]; then
        echo "Usage: sqp <partition_name>"
        return 1
    fi
    squeue -p "$1" -o '%.7i %.12u %.10P %.25j %.4t %.10M %.6D %R'
}

# ==============================================================================
#  Section 2: Interactive Job Management
# ==============================================================================

# A flexible function to get an interactive shell on a compute node.
# It intelligently selects the partition based on whether you request GPUs.
# Usage: sinteractive -g 4 -c 32 -t 4:00:00
sinteractive() {
    # --- Defaults ---
    local gpus=1
    local cpus_per_gpu=48
    local mem_per_gpu=80 # in GB
    local time="01:00:00"
    # local partition="dev"
    local qos="$QOS"
    local cmd="/bin/bash"
    local job_name="interactive"

    # --- Usage Info ---
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: sinteractive [options]"
        echo
        echo "A helper to request an interactive Slurm job."
        echo
        echo "Options:"
        echo "  -g GPUS         Number of GPUs to request (default: 1). If 0, runs on 'cpu' partition."
        echo "  -c CPUS         CPUs per GPU (default: 48)."
        echo "  -m MEM          Total memory in GB (e.g., 80, 160G) (default: 80G per GPU)."
        echo "  -t TIME         Job time limit, e.g., 0-08:00:00 or 08:00:00 (default: 01:00:00)."
        # echo "  -p PARTITION    Force a specific partition (e.g., cpu)."
        echo "  -q QOS          Force a specific QOS (e.g., $QOS)."
        echo "  -J NAME         Set a custom job name (default: interactive)."
        echo
        echo "Example: sinteractive -g 4 -c 32 -t 4:00:00 -J myjob"
        return 0
    fi

    # --- Parse Arguments ---
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g) gpus="$2"; shift 2 ;;
            -c) cpus_per_gpu="$2"; shift 2 ;;
            -m) mem_per_gpu="$2"; shift 2 ;;
            -t) time="$2"; shift 2 ;;
            # -p) partition="$2"; shift 2 ;;
            -q) qos="$2"; shift 2 ;;
            -J) job_name="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
    done

    # --- Intelligent Resource Calculation ---
    local total_cpus=$((gpus * cpus_per_gpu))

    # verify that mem_per_gpu is a number
    if ! [[ "$mem_per_gpu" =~ ^[0-9]+$ ]]; then
        echo "Error: mem_per_gpu must be a number"
        return 1
    fi

    # If no GPUs, use the memory per GPU as is
    local total_mem="${mem_per_gpu}G"
    if [ "$gpus" -gt 0 ]; then
        total_mem=$((gpus * mem_per_gpu))"G"
        echo "total_mem: $total_mem = $gpus gpus * $mem_per_gpu G/gpu"
    fi

    # # If user specifies cpus, use that value directly
    # if [[ "$cpus_per_gpu" -gt 0 && "$gpus" -eq 1 ]]; then
    #   total_cpus=$cpus_per_gpu
    # fi

    echo "Requesting job on QOS '$qos' with:"
    echo "  - GPUs: $gpus"
    echo "  - CPUs: $cpus_per_gpu"
    echo "  - Memory: $total_mem"
    echo "  - Time: $time"
    echo "  - Job Name: $job_name"
    echo "----------------------------------------------------"

    # --- Build and Run Command ---
    local base="--qos=$qos --mem=$total_mem --time=$time --job-name=$job_name --overlap"
    # testing --overlap to see if it helps with the false error:
    # > Access denied by pam_slurm_adopt: you have no active jobs on this node
    if [ "$gpus" -gt 0 ]; then
        srun_cmd="srun $base --gpus=$gpus --cpus-per-gpu=$cpus_per_gpu --nodes=1 --pty $cmd"
        # example: srun --qos=maestro_high --mem=80G --time=24:00:00 --job-name=interactive --overlap --gpus=1 --cpus-per-gpu=48 --nodes=1 --pty /bin/bash
    else
        srun_cmd="srun $base --cpus-per-task=$cpus_per_gpu --pty $cmd"
        # example: srun --qos=maestro_high --mem=80G --time=24:00:00 --job-name=interactive --overlap --cpus-per-task=48 --pty /bin/bash
    fi

    echo "Running command:"
    echo $srun_cmd
    echo "----------------------------------------------------"
    eval $srun_cmd
}

# ==============================================================================
#  Section 3: Cluster Status & Monitoring
# ==============================================================================

# Summarize the usage of individual GPUs and nodes in the 'learn' partition.
gpu-usage() {
    echo "--- Individual GPU Summary (learn partition) ---"
    
    # Get detailed GPU statistics including node states
    local stats=$(sinfo -p learn -N -o '%N %T %G' | awk '
        BEGIN {
            total_gpus_up = 0;
            total_gpus_all = 0;
            nodes_up = 0;
            nodes_down = 0;
            nodes_drain = 0;
            nodes_maint = 0;
            nodes_other = 0;
        }
        NR > 1 {
            state = tolower($2);
            if ($3 ~ /^gpu:/) {
                split($3, parts, ":");
                if (parts[3] ~ /^[0-9]+/) {
                    gpu_count = parts[3];
                    gsub(/\(.*$/, "", gpu_count);
                    total_gpus_all += gpu_count;
                    
                    # Count GPUs by node state
                    if (state ~ /down|drain|draining|maint|fail|unkn|power_save|power_down/) {
                        if (state ~ /down/) nodes_down++;
                        else if (state ~ /drain/) nodes_drain++;
                        else if (state ~ /maint/) nodes_maint++;
                        else nodes_other++;
                    } else {
                        total_gpus_up += gpu_count;
                        nodes_up++;
                    }
                }
            }
        }
        END {
            printf "%d %d %d %d %d %d %d", total_gpus_up, total_gpus_all, nodes_up, nodes_down, nodes_drain, nodes_maint, nodes_other;
        }
    ')
    
    # Parse the stats
    local total_gpus_up=$(echo $stats | awk '{print $1}')
    local total_gpus_all=$(echo $stats | awk '{print $2}')
    local nodes_up=$(echo $stats | awk '{print $3}')
    local nodes_down=$(echo $stats | awk '{print $4}')
    local nodes_drain=$(echo $stats | awk '{print $5}')
    local nodes_maint=$(echo $stats | awk '{print $6}')
    local nodes_other=$(echo $stats | awk '{print $7}')

    # Get allocated GPUs from squeue, sum only once per unique jobid
    local allocated_gpus=$(squeue -p learn -t RUNNING -o '%.7i %.10b' | awk '
        NR > 1 {
            jobid = $1;
            tres = $2;
            if (tres ~ /^gres\/gpu:/) {
                split(tres, parts, ":");
                if (parts[2] ~ /^[0-9]+$/) {
                    if (!(jobid in seen)) {
                        seen[jobid]=1;
                        total += parts[2];
                    }
                }
            }
        }
        END { print total }
    ')

    local available_gpus=$((total_gpus_up - allocated_gpus))
    local down_gpus=$((total_gpus_all - total_gpus_up))
    
    printf "%-12s | %s\n" "METRIC" "GPU COUNT"
    echo "------------------------"
    printf "%-12s | %d\n" "Allocated" "$allocated_gpus"
    printf "%-12s | %d\n" "Available" "$available_gpus"
    printf "%-12s | %d\n" "Down/Unavail" "$down_gpus"
    echo "------------------------"
    printf "%-12s | %d\n" "Total (up)" "$total_gpus_up"
    printf "%-12s | %d\n" "Total (all)" "$total_gpus_all"
    echo ""
    echo "--- Node Status Breakdown ---"
    printf "%-12s | %s\n" "STATE" "NODE COUNT"
    echo "------------------------"
    printf "%-12s | %d\n" "Up" "$nodes_up"
    printf "%-12s | %d\n" "Down" "$nodes_down"
    printf "%-12s | %d\n" "Draining" "$nodes_drain"
    printf "%-12s | %d\n" "Maintenance" "$nodes_maint"
    printf "%-12s | %d\n" "Other" "$nodes_other"
}

# Summarize the state and core usage of the 'cpu' partition.
cpu-usage() {
    echo "--- CPU Node & Core Summary (cpu partition) ---"
    sinfo -p cpu -s -o "%n %T %C" | awk '
        BEGIN {
            nodes_total=0; nodes_idle=0; nodes_alloc=0; nodes_mixed=0; nodes_other=0;
            cores_total=0; cores_alloc=0;
            printf "%-12s | %-12s | %-12s\n", "STATE", "NODE COUNT", "CORE COUNT";
            print "-------------------------------------------";
        }
        NR > 1 {
            nodes_total++;
            if ($2 == "idle") nodes_idle++;
            else if ($2 == "alloc") nodes_alloc++;
            else if ($2 == "mixed") nodes_mixed++;
            else nodes_other++;
            
            split($3, c, "/");
            cores_alloc += c[1];
            cores_total += c[4];
        }
        END {
            printf "%-12s | %-12d | %-12d\n", "Idle", nodes_idle, cores_total - cores_alloc;
            printf "%-12s | %-12d | %-12d\n", "Allocated", nodes_alloc, cores_alloc;
            printf "%-12s | %-12d | %s\n", "Mixed", nodes_mixed, "N/A";
            printf "%-12s | %-12d | %s\n", "Other", nodes_other, "N/A";
            print "-------------------------------------------";
            printf "%-12s | %-12d | %-12d\n", "Total", nodes_total, cores_total;
        }
    '
}

# Show partition usage summary
partition-usage() {
    echo "--- Partition Usage Summary ---"
    sinfo -o "%P %A %D %T" | awk '
        BEGIN {
            printf "%-12s | %-8s | %-8s | %s\n", "PARTITION", "ALLOC", "NODES", "STATE";
            print "------------------------------------------------";
        }
        NR > 1 {
            split($2, alloc, "/");
            split($3, nodes, "/");
            printf "%-12s | %-8s | %-8s | %s\n", $1, alloc[1], nodes[1], $4;
        }
    '
}

# Show cluster load summary
cluster-load() {
    echo "--- Cluster Load Summary ---"
    sinfo -o "%P %A %D %T %C %G" | awk '
        BEGIN {
            printf "%-12s | %-8s | %-8s | %-10s | %-20s | %s\n", "PARTITION", "ALLOC", "NODES", "STATE", "CPUS", "GPUS";
            print "------------------------------------------------------------------------------------------";
        }
        NR > 1 {
            split($2, alloc, "/");
            split($3, nodes, "/");
            printf "%-12s | %-8s | %-8s | %-10s | %-20s | %s\n", $1, alloc[1], nodes[1], $4, $5, $6;
        }
    '
}

# ==============================================================================
#  Section 4: User & Job Analysis
# ==============================================================================

# Summarize resource usage by user, sorted descending by total GPU count.
susers() {
    echo "--- Resource Usage by User (Running Jobs) ---"
    squeue -t RUNNING -o "%.15u %.7i %.10b" | awk '
        NR > 1 {
            user = $1;
            jobid = $2;
            tres = $3;
            
            # Only process jobs that actually use GPUs
            if (tres ~ /^gres\/gpu:/) {
                split(tres, parts, ":");
                if (parts[2] ~ /^[0-9]+$/) {
                    gpu_count = parts[2];
                    
                    # Count unique jobs per user
                    if (!(user in user_jobs)) {
                        user_jobs[user] = 0;
                        user_gpus[user] = 0;
                    }
                    
                    # Only count each job once per user
                    if (!(jobid in seen_jobs)) {
                        seen_jobs[jobid] = 1;
                        user_jobs[user]++;
                        user_gpus[user] += gpu_count;
                    }
                }
            }
        }
        END {
            # Sort by GPU count (descending)
            for (u in user_gpus) {
                printf "%d\t%s\t%d\t%d\n", user_gpus[u], u, user_gpus[u], user_jobs[u];
            }
        }
    ' | sort -k1,1nr | awk '
        BEGIN {
            printf "%-15s | %-10s | %-10s\n", "USER", "GPU_COUNT", "JOB_COUNT";
            print "---------------------------------------";
        }
        {
            printf "%-15s | %-10d | %-10d\n", $2, $3, $4;
        }
    '
}

# Show your resource usage summary
my-usage() {
    echo "--- Your Resource Usage Summary ---"
    local running_jobs=$(squeue -u $USER -t RUNNING --noheader | wc -l)
    local pending_jobs=$(squeue -u $USER -t PENDING --noheader | wc -l)
    local total_gpus=$(squeue -u $USER -t RUNNING -o "%.10b" | awk '
        NR > 1 {
            if ($1 ~ /^gres\/gpu:/) {
                split($1, parts, ":");
                if (parts[2] ~ /^[0-9]+$/) {
                    total += parts[2];
                }
            }
        }
        END { print total }
    ')
    
    printf "Running jobs: %d\n" "$running_jobs"
    printf "Pending jobs: %d\n" "$pending_jobs"
    printf "Total GPUs allocated: %d\n" "$total_gpus"
    
    if [ "$running_jobs" -gt 0 ]; then
        echo ""
        echo "--- Your Running Jobs ---"
        squeue -u $USER -t RUNNING -o "%.7i %.12P %.25j %.4t %.10M %.6D %R"
    fi
}

# Show your job efficiency summary
my-efficiency() {
    echo "--- Your Job Efficiency Summary ---"
    sacct -u $USER --starttime=now-7days --format=JobID,JobName,Partition,AllocCPUS,ReqMem,State,Elapsed,MaxRSS | awk '
        NR > 1 && $6 == "COMPLETED" {
            if ($8 != "" && $8 != "0") {
                printf "Job %s: %s CPUs, %s mem, %s runtime, %s max RSS\n", $1, $4, $5, $7, $8;
            }
        }
    '
}

# Show jobs that are likely stuck or problematic
stuck-jobs() {
    echo "--- Potentially Stuck Jobs ---"
    squeue -t PENDING -o "%.7i %.12u %.10P %.25j %.4t %.10M %.6D %R" | awk '
        NR > 1 {
            if ($5 ~ /^[0-9]+$/) {
                if ($5 > 60) {  # Pending for more than 60 minutes
                    printf "Job %s (user: %s, partition: %s) pending for %s minutes\n", $1, $2, $3, $5;
                }
            }
        }
    '
}

# Show jobs sorted by priority
priority-jobs() {
    echo "--- Jobs by Priority (Pending) ---"
    squeue -t PENDING -o "%.7i %.12u %.10P %.25j %.4t %.10M %.6D %R %.10Q" | head -1 && \
    squeue -t PENDING -o "%.7i %.12u %.10P %.25j %.4t %.10M %.6D %R %.10Q" | awk 'NR > 1' | sort -k9,9nr
}

# ==============================================================================
#  Section 5: Job Management & Control
# ==============================================================================

# Kill all your running jobs with confirmation
scancel-running() {
    echo "This will cancel ALL your running jobs. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        scancel -t RUNNING -u $USER
        echo "All running jobs cancelled."
    else
        echo "Cancelled."
    fi
}

# Kill all your jobs (running + pending) with confirmation
scancel-all() {
    echo "This will cancel ALL your jobs (running + pending). Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        scancel -u $USER
        echo "All jobs cancelled."
    else
        echo "Cancelled."
    fi
}

# Show detailed job information. Usage: sjob <jobid>
sjob() {
    if [ -z "$1" ]; then
        echo "Usage: sjob <jobid>"
        return 1
    fi
    scontrol show job "$1"
}


# Show job history for the last N days. Usage: shistory [days]
shistory() {
    local days=${1:-7}
    echo "--- Job History (last $days days) ---"
    sacct --starttime=now-${days}days --format=JobID,JobName,Partition,AllocCPUS,ReqMem,State,ExitCode,Elapsed,MaxRSS
}

# Get detailed accounting info for a completed job. Usage: sdetails <jobid>
sdetails() {
    if [ -z "$1" ]; then
        echo "Usage: sdetails <jobid>"
        return 1
    fi
    sacct -j "$1" --format=JobID,JobName,Partition,AllocCPUS,ReqMem,MaxRSS,State,ExitCode,End
}

# ==============================================================================
#  Section 6: Advanced Monitoring
# ==============================================================================

# Show node details for a specific partition. Usage: snodes [partition]
snodes() {
    local partition=${1:-learn}
    echo "--- Node Details for partition: $partition ---"
    sinfo -p "$partition" -N -o "%N %T %C %G %m %f" | head -1 && \
    sinfo -p "$partition" -N -o "%N %T %C %G %m %f" | awk 'NR > 1'
}

# Show GPU utilization by node
gpu-utilization() {
    echo "--- GPU Utilization by Node ---"
    sinfo -p learn -N -o "%N %T %G" | awk '
        NR > 1 {
            if ($3 ~ /^gpu:/) {
                split($3, parts, ":");
                if (parts[3] ~ /^[0-9]+/) {
                    gpu_count = parts[3];
                    gsub(/\(.*$/, "", gpu_count);
                    if (tolower($2) ~ /alloc/) {
                        printf "%-20s | %-8s | %s GPUs\n", $1, $2, gpu_count;
                    }
                }
            }
        }
    '
}

# Show your job queue with more details
my-jobs-detailed() {
    echo "--- Your Jobs (Detailed) ---"
    squeue -u $USER -o "%.7i %.12P %.25j %.4t %.10M %.6D %.10Q %R" | head -1 && \
    squeue -u $USER -o "%.7i %.12P %.25j %.4t %.10M %.6D %.10Q %R" | awk 'NR > 1'
}

# Show usage vs limits for a specific QoS (default: $QOS). Usage: qos-usage [qos]
qos-usage() {
    local qos=${1:-$QOS}
    if [[ -z "$qos" ]]; then
        echo "Usage: qos-usage [qos]"
        return 1
    fi

    echo "--- QoS Usage: ${qos} ---"

    # Fetch QoS limits
    local grp=$(sacctmgr -np show qos where name=${qos} format=GrpTRES 2>/dev/null | awk -F'|' 'NR==1{print $1}')
    local limit_gpu=$(echo "$grp" | awk -F',' '{for(i=1;i<=NF;i++){if($i~"gres/gpu="){split($i,a,"=");print a[2]; exit}}}')
    local limit_cpu=$(echo "$grp" | awk -F',' '{for(i=1;i<=NF;i++){if($i~"cpu="){split($i,a,"=");print a[2]; exit}}}')

    # Current usage (RUNNING jobs only) — robustly sum GPUs from AllocTRES via scontrol
    local allocated=$(
        jobids=$(squeue --qos=${qos} -h -t RUNNING -o "%i" 2>/dev/null);
        used_gpu=0; used_cpu=0;
        for jid in $jobids; do
            line=$(scontrol show job -o "$jid" 2>/dev/null)
            # GPUs from AllocTRES (total per job)
            atres=$(echo "$line" | grep -o 'AllocTRES=[^ ]*' | sed 's/AllocTRES=//')
            g=$(echo "$atres" | awk -F',' '{for(i=1;i<=NF;i++){if($i~"^gres/gpu="){split($i,a,"="); print a[2]; exit}}}')
            if [[ -z "$g" ]]; then
                g=$(echo "$line" | grep -o 'TresPerNode=gres/gpu:[0-9]*' | sed 's/.*://')
            fi
            # CPUs from squeue (faster, reliable)
            c=$(squeue -h -j "$jid" -o "%C" 2>/dev/null)
            used_gpu=$((used_gpu + ${g:-0}))
            used_cpu=$((used_cpu + ${c:-0}))
        done
        printf "%d %d" "$used_gpu" "$used_cpu"
    )
    local used_gpu=$(echo "$allocated" | awk '{print $1}')
    local used_cpu=$(echo "$allocated" | awk '{print $2}')

    local free_gpu="N/A"; local free_cpu="N/A"
    if [[ -n "$limit_gpu" ]]; then free_gpu=$((limit_gpu - used_gpu)); fi
    if [[ -n "$limit_cpu" ]]; then free_cpu=$((limit_cpu - used_cpu)); fi

    printf "%-14s | %s\n" "Limit GPUs" "${limit_gpu:-N/A}"
    printf "%-14s | %s\n" "Used GPUs"  "${used_gpu:-0}"
    printf "%-14s | %s\n" "Free GPUs"  "${free_gpu}"
    echo "------------------------------"
    printf "%-14s | %s\n" "Limit CPUs" "${limit_cpu:-N/A}"
    printf "%-14s | %s\n" "Used CPUs"  "${used_cpu:-0}"
    printf "%-14s | %s\n" "Free CPUs"  "${free_cpu}"
}

# ==============================================================================
#  Section 7: Quick Access Aliases
# ==============================================================================

# Watch your personal job queue.
alias watch-jobs="watch -d -n 5 squeue -u $USER -o '%.7i %.12P %.25j %.4t %.10M %.6D %R'"

# Check your storage quota on the /checkpoint filesystem.
# NOTE: lfs is not a standard command, but is common on Lustre systems.
# If this fails, you may need to find the cluster-specific quota command.
alias squota="lfs quota -u $USER /checkpoint/maestro/$USER"

# Cancel ALL of your PENDING jobs with an interactive confirmation prompt.
alias scancel-pending="scancel -i -t PENDING -u $USER"

# Quick aliases for common tasks
alias sqme-detailed="squeue -u $USER -o '%.7i %.12P %.25j %.4t %.10M %.6D %.10Q %R'"
alias watch-gpu="watch -d -n 5 'bash -c \"source \${DOTFILES:-\$HOME/dotfiles}/slurm/slurm_aliases.sh && gpu-usage\"'"
alias watch-users="watch -d -n 5 'bash -c \"source \${DOTFILES:-\$HOME/dotfiles}/slurm/slurm_aliases.sh && susers\"'"
alias pending-jobs="squeue -t PENDING"
alias running-jobs="squeue -t RUNNING"
alias cluster-status="sinfo -o '%P %A %D %T'"

# ==============================================================================
#  Section 9: Direct SSH Access Aliases (for VS Code/Cursor)
# ==============================================================================

# Generic helper to launch a persistent tmux session with sinteractive for SSH/VSCode
# Usage: sdev_tmux_ssh <session_name> [--gpus=N] [--cpus=N] [--mem=N] [--hours=N]
sdev_tmux_ssh() {
    local session_name="$1"
    shift
    # Defaults
    local gpus=1
    local cpus_per_gpu=48
    local mem_per_gpu=186
    local hours=168


    usage () {
        echo "Usage: sdev_tmux_ssh <session_name> [--gpus=N] [--cpus=N] [--mem=N] [--hours=N] [--qos=QOS]"
        echo "Defaults: --gpus=1 --cpus=48 --mem=186 --hours=168 (7 days) --qos=h200_maestro_high"
        echo "Example: sdev_tmux_ssh ssh4 --gpus=4 --cpus=8 --mem=80 --hours=168 --qos=h200_maestro_high"
    }

    # Parse kwargs
    for arg in "$@"; do
        case $arg in
            --gpus=*) gpus="${arg#*=}" ;;
            --cpus=*) cpus_per_gpu="${arg#*=}" ;;
            --mem=*) mem_per_gpu="${arg#*=}" ;;
            --hours=*) hours="${arg#*=}" ;;
            --qos=*) qos="${arg#*=}" ;;
            *) echo "Unknown argument: $arg"; usage; return 1 ;;
        esac
    done

    local time_limit="${hours}:00:00"

    if [[ -z "$session_name" ]]; then
        usage
        return 1
    fi

    echo "Starting ${gpus}-GPU job for SSH access (${hours} hours)..."
    echo "This will create a persistent tmux session ($session_name) that survives disconnections."

    tmux new-session -d -s "$session_name" "source \${DOTFILES:-\$HOME/dotfiles}/slurm/slurm_aliases.sh && sinteractive -g $gpus -c $cpus_per_gpu -m $mem_per_gpu -t $time_limit -J $session_name -q $qos; exec bash"

    echo "Job started in tmux session: $session_name"
    echo "SSH to the node shown in NODELIST when the job shows as RUNNING"
    sleep 3
    squeue -u $USER -t RUNNING -o "%7i %12P %25j %4t %10M %6D %R" | grep " $session_name "
    echo ""
}

# Shortcuts for common cases (no params)
sdev-cpu-x24() { sdev_tmux_ssh cpu-x24 --qos=cpu_lowest --gpus=0 --cpus=24 --mem=186 --hours=168; }
sdev-cpu-x48() { sdev_tmux_ssh cpu-x48 --qos=cpu_lowest --gpus=0 --cpus=48 --mem=372 --hours=168; }
sdev-cpu-x96() { sdev_tmux_ssh cpu-x96 --qos=cpu_lowest --gpus=0 --cpus=96 --mem=744 --hours=168; }
sdev-gpu-x1() { sdev_tmux_ssh gpu-x1 --qos=$QOS --gpus=1 --cpus=16 --mem=186 --hours=168; }
sdev-gpu-x4() { sdev_tmux_ssh gpu-x4 --qos=$QOS --gpus=4 --cpus=16 --mem=186 --hours=168; }
sdev-gpu-x8() { sdev_tmux_ssh gpu-x8 --qos=$QOS --gpus=8 --cpus=16 --mem=186 --hours=168; }

# Helper function to show which nodes you can SSH to
ssh-nodes() {
    echo "--- Nodes you can SSH to (based on running jobs) ---"
    squeue -u $USER -t RUNNING -o "%.7i %.12P %.25j %.4t %.10M %.6D %R" | awk '
        NR > 1 {
            printf "Job %s: SSH to %s (partition: %s, time: %s)\n", $1, $7, $2, $5;
        }
    '
}
