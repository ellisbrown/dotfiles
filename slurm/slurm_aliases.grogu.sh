#!/bin/bash

# courtesy of alex li

# GROGU
body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}

# alias si="sinfo -o \"%20P %5D %14F %8z %10m %10d %11l %16f %N\""
alias si="sinfo --Node -O Partition:14,NodeList:15,StateLong:12,GresUsed:30,Gres,FreeMem:12,CPUsState:20 | grep 'long\|NODELIST' | body sort"
alias sig="sinfo --Node -O Partition:14,NodeList:15,StateLong:12,GresUsed:30,Gres,FreeMem:12,CPUsState:20 | grep 'long\|NODELIST' | body sort | grep 'GRES_USED\|rtx3090\|rtx6000\|A5000\|A6000'"
alias sime="sinfo --Node -O Partition:14,NodeList:15,StateLong:12,GresUsed:30,Gres,FreeMem:12,CPUsState:20 | grep 'deepaklong\|NODELIST' | body sort"
alias sq="squeue --sort=\"P,U,t,-p\" -o \"%6i %36j %4t %10u %10q %12P %10Q %5D %11l %11L %16R %8b %5C %m\""
alias sqme="squeue -o \"%6i %50j %4t %10u %10q %12P %10Q %5D %11l %11L %16R %8b %5C %m\" -u $USER | nl -v 0"
alias sqd="squeue --sort=\"U,t,-p\" -o \"%6i %36j %4t %10u %10q %12P %10Q %5D %11l %11L %16R %8b %5C %m\" | body grep '0-19 \|1-19 \|1-40 \|1-3 \|0-24 \|deepak'"
alias sc="scontrol show node"


getbash () {
        local MEM="${4:-56}G"
        srun -N 1 -t 0-48:00:00 -G "$2" -c "$3" -W 0 --partition=deepaklong --nodelist="grogu-$1" --mem="$MEM" --pty /bin/bash -i
}
getbasha () {
        local MEM="${4:-56}G"
	srun -N 1 -t 0-48:00:00 -G "$2" -c "$3" -W 0 --partition=abhinavlong --nodelist="grogu-$1" --mem="$MEM" --pty /bin/bash -i
}

# Greene
alias si100="sinfo -s | grep 'a100\|NODELIST' | body sort"

watchquota() {
	watch -d -n 0.5 "squeue -u $(whoami) -o '%.18i %.20P %.15j %.8u %.2t %.10M %.6D %.20S %R %p'"
}
watchusage() {
	watch -d -n 1.0 "sinfo -N -p a100_1,a100_2,rtx8000 -O 'NodeList:8,Partition:12,StateCompact:24,CPUsState:16,Memory:16,FreeMem:16,GresUsed:24' | grep -v '4(IDX:0-3)'"
}