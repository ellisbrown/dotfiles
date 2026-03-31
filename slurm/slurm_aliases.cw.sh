#!/bin/bash
#
# ==============================================================================
#  Slurm Aliases and Functions for the CoreWeave (CW) Cluster
# ==============================================================================
#
# Cluster: dm1-control
# GPUs: H100 (8 per node, 128 CPUs per node, ~1.8 TB mem per node)
# Partitions: learn (1424 nodes), obtest (2 nodes)
# Accounts: fair_amaia_cw_explore (interactive), fair_amaia_cw_video (training)
# QoS tiers: dev (100), explore (10), scale (5), lowest (1)

# --- Helper function to keep header on sorted output ---
body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}

# --- Cluster defaults ---
CW_ACCOUNT="fair_amaia_cw_explore"
CW_QOS="dev"
CW_ACCOUNT_TRAIN="fair_amaia_cw_video"

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

# Show obtest partition (quick testing nodes).
alias sitest="sinfo -N -p obtest -o '%25N %12S %C %10m %10f %G'"

# A wide, sorted view of all jobs in the queue with GPU count.
alias sq="squeue -o '%.7i %.12u %.10P %.25j %.4t %.10M %.6D %.10b %S %R' --sort=-p"

# Show only my jobs, with a line number, CPU count, and GPU count.
alias sqme="squeue -u $USER -o '%.7i %.12P %.25j %.4t %.10M %.6D %.4C %.10b %R' | nl -v 0"

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
# Uses CW account/QoS model with --gres=gpu:h100:N for GPU specification.
# Usage: sinteractive -g 4 -c 14 -t 4:00:00
sinteractive() {
    # --- Defaults ---
    local gpus=1
    local cpus_per_gpu=14
    local mem_per_gpu=220 # in GB
    local time="01:00:00"
    local partition="learn"
    local account="$CW_ACCOUNT"
    local qos="$CW_QOS"
    local cmd="/bin/bash"
    local job_name="interactive"

    # --- Usage Info ---
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: sinteractive [options]"
        echo
        echo "A helper to request an interactive Slurm job on CW cluster."
        echo
        echo "Options:"
        echo "  -g GPUS         Number of GPUs to request (default: 1). If 0, CPU-only."
        echo "  -c CPUS         CPUs per GPU (default: 14)."
        echo "  -m MEM          Memory in GB per GPU (default: 220)."
        echo "  -t TIME         Job time limit, e.g., 0-08:00:00 or 08:00:00 (default: 01:00:00)."
        echo "  -p PARTITION    Partition (default: learn). Use 'obtest' for quick testing."
        echo "  -a ACCOUNT      Account (default: $CW_ACCOUNT)."
        echo "  -q QOS          QOS (default: $CW_QOS). Options: dev, explore, lowest, scale."
        echo "  -J NAME         Set a custom job name (default: interactive)."
        echo
        echo "Accounts:  fair_amaia_cw_explore (interactive), fair_amaia_cw_video (training)"
        echo "QoS tiers: dev (pri 100, 1d max), explore (pri 10), scale (pri 5), lowest (pri 1)"
        echo
        echo "Example: sinteractive -g 4 -c 14 -t 4:00:00 -J myjob"
        echo "Example: sinteractive -p obtest -g 1 -t 8:00:00   # quick test on idle nodes"
        echo "Example: sinteractive -a fair_amaia_cw_video -q scale -g 8 -t 24:00:00"
        return 0
    fi

    # --- Parse Arguments ---
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g) gpus="$2"; shift 2 ;;
            -c) cpus_per_gpu="$2"; shift 2 ;;
            -m) mem_per_gpu="$2"; shift 2 ;;
            -t) time="$2"; shift 2 ;;
            -p) partition="$2"; shift 2 ;;
            -a) account="$2"; shift 2 ;;
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

    local total_mem="${mem_per_gpu}G"
    if [ "$gpus" -gt 0 ]; then
        total_mem=$((gpus * mem_per_gpu))"G"
        echo "total_mem: $total_mem = $gpus gpus * $mem_per_gpu G/gpu"
    fi

    echo "Requesting job on partition '$partition' with account '$account', QoS '$qos':"
    echo "  - GPUs: $gpus (H100)"
    echo "  - CPUs: $total_cpus ($cpus_per_gpu per GPU)"
    echo "  - Memory: $total_mem"
    echo "  - Time: $time"
    echo "  - Job Name: $job_name"
    echo "----------------------------------------------------"

    # --- Build and Run Command ---
    local srun_cmd=(srun --partition="$partition" --account="$account" --qos="$qos"
                    --mem="$total_mem" --time="$time" --job-name="$job_name" --overlap)
    if [ "$gpus" -gt 0 ]; then
        srun_cmd+=(--gres="gpu:h100:$gpus" --cpus-per-task="$total_cpus" --nodes=1 --pty "$cmd")
    else
        srun_cmd+=(--cpus-per-task="$total_cpus" --pty "$cmd")
    fi

    echo "Running command:"
    echo "${srun_cmd[*]}"
    echo "----------------------------------------------------"
    "${srun_cmd[@]}"
}

# ==============================================================================
#  Section 3: Cluster Status & Monitoring
# ==============================================================================

# Summarize the usage of individual GPUs and nodes in the 'learn' partition.
gpu-usage() {
    echo "--- Individual GPU Summary (learn partition) ---"

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
            if ($3 ~ /gpu/) {
                split($3, parts, ":");
                # Handle gres format: gpu:h100:8(S:0-7)
                gpu_count = parts[3];
                gsub(/\(.*$/, "", gpu_count);
                if (gpu_count ~ /^[0-9]+$/) {
                    total_gpus_all += gpu_count;

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

    local total_gpus_up=$(echo $stats | awk '{print $1}')
    local total_gpus_all=$(echo $stats | awk '{print $2}')
    local nodes_up=$(echo $stats | awk '{print $3}')
    local nodes_down=$(echo $stats | awk '{print $4}')
    local nodes_drain=$(echo $stats | awk '{print $5}')
    local nodes_maint=$(echo $stats | awk '{print $6}')
    local nodes_other=$(echo $stats | awk '{print $7}')

    # Get allocated GPUs from squeue
    local allocated_gpus=$(squeue -p learn -t RUNNING -o '%.7i %.10b' | awk '
        NR > 1 {
            jobid = $1;
            tres = $2;
            if (tres ~ /gpu/) {
                split(tres, parts, ":");
                # Handle gres/gpu:h100:N format
                for (i in parts) {
                    if (parts[i] ~ /^[0-9]+$/) {
                        gpu_count = parts[i];
                    }
                }
                if (!(jobid in seen)) {
                    seen[jobid]=1;
                    total += gpu_count;
                }
            }
        }
        END { print total+0 }
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

# Show obtest partition status (quick testing nodes)
obtest-status() {
    echo "--- obtest Partition Status ---"
    local idle=$(sinfo -p obtest -N -h -t idle 2>/dev/null | wc -l)
    local total=$(sinfo -p obtest -N -h 2>/dev/null | wc -l)
    if [ "$idle" -gt 0 ]; then
        echo "  ${idle}/${total} nodes IDLE - great for quick testing!"
    else
        echo "  No idle nodes - obtest is busy"
    fi
    sinfo -p obtest -N -h -o "%n %t %G" 2>/dev/null | awk '{printf "  %-20s %-10s %s\n", $1, $2, $3}'
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

            if (tres ~ /gpu/) {
                # Extract GPU count from gres/gpu:h100:N or gres/gpu:N
                n = split(tres, parts, ":");
                gpu_count = parts[n];
                gsub(/[^0-9]/, "", gpu_count);

                if (gpu_count > 0) {
                    if (!(user in user_jobs)) {
                        user_jobs[user] = 0;
                        user_gpus[user] = 0;
                    }
                    if (!(jobid in seen_jobs)) {
                        seen_jobs[jobid] = 1;
                        user_jobs[user]++;
                        user_gpus[user] += gpu_count;
                    }
                }
            }
        }
        END {
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
            if ($1 ~ /gpu/) {
                n = split($1, parts, ":");
                g = parts[n];
                gsub(/[^0-9]/, "", g);
                total += g;
            }
        }
        END { print total+0 }
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
    echo "--- Potentially Stuck Jobs (pending > 60 min) ---"
    squeue -t PENDING -o "%.7i %.12u %.10P %.25j %.4t %.10M %.6D %R" | awk '
        NR > 1 {
            time_str = $6;
            minutes = 0;
            if (time_str ~ /-/) {
                split(time_str, dp, "-");
                minutes += dp[1] * 24 * 60;
                time_str = dp[2];
            }
            n = split(time_str, tp, ":");
            if (n == 3) {
                minutes += tp[1] * 60 + tp[2];
            } else if (n == 2) {
                minutes += tp[1];
            }
            if (minutes > 60) {
                printf "Job %s (user: %s, partition: %s) pending for %s\n", $1, $2, $3, $6;
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
            if ($3 ~ /gpu/) {
                split($3, parts, ":");
                gpu_count = parts[3];
                gsub(/\(.*$/, "", gpu_count);
                if (gpu_count ~ /^[0-9]+/ && tolower($2) ~ /alloc/) {
                    printf "%-20s | %-8s | %s GPUs\n", $1, $2, gpu_count;
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

# Show usage vs limits for a specific QoS. Usage: qos-usage [qos]
qos-usage() {
    local qos=${1:-$CW_QOS}
    if [[ -z "$qos" ]]; then
        echo "Usage: qos-usage [qos]"
        return 1
    fi

    echo "--- QoS Usage: ${qos} ---"

    local grp=$(sacctmgr -np show qos where name=${qos} format=GrpTRES 2>/dev/null | awk -F'|' 'NR==1{print $1}')
    local limit_gpu=$(echo "$grp" | awk -F',' '{for(i=1;i<=NF;i++){if($i~"gres/gpu="){split($i,a,"=");print a[2]; exit}}}')
    local limit_cpu=$(echo "$grp" | awk -F',' '{for(i=1;i<=NF;i++){if($i~"cpu="){split($i,a,"=");print a[2]; exit}}}')

    local allocated=$(
        jobids=$(squeue --qos=${qos} -h -t RUNNING -o "%i" 2>/dev/null);
        used_gpu=0; used_cpu=0;
        for jid in $jobids; do
            line=$(scontrol show job -o "$jid" 2>/dev/null)
            atres=$(echo "$line" | grep -o 'AllocTRES=[^ ]*' | sed 's/AllocTRES=//')
            g=$(echo "$atres" | awk -F',' '{for(i=1;i<=NF;i++){if($i~"^gres/gpu="){split($i,a,"="); print a[2]; exit}}}')
            if [[ -z "$g" ]]; then
                g=$(echo "$line" | grep -o 'TresPerNode=gres/gpu:[0-9]*' | sed 's/.*://')
            fi
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
#  Section 8: Direct SSH Access Aliases (for VS Code/Cursor)
# ==============================================================================

# Generic helper to launch a persistent tmux session with sinteractive for SSH/VSCode
# Usage: sdev_tmux_ssh <session_name> [--gpus=N] [--cpus=N] [--mem=N] [--hours=N] [--account=A] [--qos=Q] [--partition=P]
sdev_tmux_ssh() {
    local session_name="$1"
    shift
    # Defaults
    local gpus=1
    local cpus_per_gpu=14
    local mem_per_gpu=220
    local hours=24
    local account="$CW_ACCOUNT"
    local qos="$CW_QOS"
    local partition="learn"

    usage () {
        echo "Usage: sdev_tmux_ssh <session_name> [--gpus=N] [--cpus=N] [--mem=N] [--hours=N] [--account=A] [--qos=Q] [--partition=P]"
        echo "Defaults: --gpus=1 --cpus=14 --mem=220 --hours=24 --account=$CW_ACCOUNT --qos=$CW_QOS --partition=learn"
        echo "Example: sdev_tmux_ssh ssh4 --gpus=4 --hours=24"
        echo "Example: sdev_tmux_ssh obtest1 --partition=obtest --gpus=1"
    }

    # Parse kwargs
    for arg in "$@"; do
        case $arg in
            --gpus=*) gpus="${arg#*=}" ;;
            --cpus=*) cpus_per_gpu="${arg#*=}" ;;
            --mem=*) mem_per_gpu="${arg#*=}" ;;
            --hours=*) hours="${arg#*=}" ;;
            --account=*) account="${arg#*=}" ;;
            --qos=*) qos="${arg#*=}" ;;
            --partition=*) partition="${arg#*=}" ;;
            *) echo "Unknown argument: $arg"; usage; return 1 ;;
        esac
    done

    local time_limit="${hours}:00:00"

    if [[ -z "$session_name" ]]; then
        usage
        return 1
    fi

    echo "Starting ${gpus}-GPU job for SSH access (${hours} hours)..."
    echo "  Partition: $partition | Account: $account | QoS: $qos"
    echo "This will create a persistent tmux session ($session_name) that survives disconnections."

    tmux new-session -d -s "$session_name" "source \${DOTFILES:-\$HOME/dotfiles}/slurm/slurm_aliases.sh && sinteractive -g $gpus -c $cpus_per_gpu -m $mem_per_gpu -t $time_limit -J $session_name -a $account -q $qos -p $partition; exec bash"

    echo "Job started in tmux session: $session_name"
    echo "SSH to the node shown in NODELIST when the job shows as RUNNING"
    sleep 3
    squeue -u $USER -t RUNNING -o "%7i %12P %25j %4t %10M %6D %R" | grep " $session_name "
    echo ""
}

# --- dev QoS shortcuts (24h max, priority 100) ---
sdev-gpu-x1() { sdev_tmux_ssh gpu-x1 --gpus=1 --cpus=14 --mem=220 --hours=24; }
sdev-gpu-x4() { sdev_tmux_ssh gpu-x4 --gpus=4 --cpus=14 --mem=220 --hours=24; }
sdev-gpu-x8() { sdev_tmux_ssh gpu-x8 --gpus=8 --cpus=14 --mem=220 --hours=24; }
sdev-cpu-x24() { sdev_tmux_ssh cpu-x24 --gpus=0 --cpus=24 --mem=220 --hours=24; }

# --- explore QoS shortcuts (no time limit, priority 10) ---
sdev-gpu-x1-long() { sdev_tmux_ssh gpu-x1-long --gpus=1 --cpus=14 --mem=220 --hours=168 --qos=explore; }
sdev-gpu-x4-long() { sdev_tmux_ssh gpu-x4-long --gpus=4 --cpus=14 --mem=220 --hours=168 --qos=explore; }
sdev-gpu-x8-long() { sdev_tmux_ssh gpu-x8-long --gpus=8 --cpus=14 --mem=220 --hours=168 --qos=explore; }

# --- obtest partition shortcuts (idle nodes, quick testing) ---
sdev-obtest-x1() { sdev_tmux_ssh obtest-x1 --partition=obtest --gpus=1 --cpus=14 --mem=220 --hours=24; }
sdev-obtest-x8() { sdev_tmux_ssh obtest-x8 --partition=obtest --gpus=8 --cpus=14 --mem=220 --hours=24; }

# Helper function to show which nodes you can SSH to
ssh-nodes() {
    echo "--- Nodes you can SSH to (based on running jobs) ---"
    squeue -u $USER -t RUNNING -o "%.7i %.12P %.25j %.4t %.10M %.6D %R" | awk '
        NR > 1 {
            printf "Job %s: SSH to %s (partition: %s, time: %s)\n", $1, $7, $2, $5;
        }
    '
}
