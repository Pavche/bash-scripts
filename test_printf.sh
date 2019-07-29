#!/bin/bahs

MODE=aggressive
DH_GROUP=5
PHASE1_AL=aes

length=43
printf -v line '%*s' "$length"
echo ${line// /-}
printf "| %-39s |\n" "Starting Racoon VPN server"
echo ${line// /-}

printf "| %-24s | %-12s |\n" "Mode" "$MODE"
printf "| %-24s | %-12s |\n" "Diffie-Hellman Groups" "$DH_GROUP"
printf "| %-24s | %-12s |\n" "Phase 1 Algorithm" "$PHASE1_AL"
echo ${line// /-}



    length=43
    printf -v line '%*s' "$length"
    echo ${line// /-}
    printf "| %-39s |\n" "Delete previous Racoon setup"
    echo ${line// /-}

