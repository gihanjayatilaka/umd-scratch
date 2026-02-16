#!/usr/bin/env bash
set -euo pipefail

NODE_LIST="$HOME/scratchfinder/allNode.txt"
SCRIPT="/vulcanscratch/gihan/audio-relatedwork/mips/copy-data-to-scratch.sh"
LOG_DIR="/vulcanscratch/gihan/audio-relatedwork/mips/log/copying"

mkdir -p "$LOG_DIR"

if [ ! -f "$NODE_LIST" ]; then
    echo "ERROR: Node list not found: ${NODE_LIST}"
    exit 1
fi

if [ ! -f "$SCRIPT" ]; then
    echo "ERROR: Script not found: ${SCRIPT}"
    exit 1
fi

COUNT=0

while IFS= read -r node || [ -n "$node" ]; do
    # skip empty lines and comments
    [[ -z "$node" || "$node" == \#* ]] && continue

    echo "Submitting job for node: ${node}"
    sbatch --account=scavenger --partition=scavenger --cpus-per-task=1 --gres=gpu:1 --mem=4gb --qos=scavenger --time=0-20:00:00 \
        --nodelist="$node" --wrap="bash ${SCRIPT} && touch ${LOG_DIR}/${node}.txt" --job-name="copy-${node}" --output="/vulcanscratch/gihan/audio-relatedwork/mips/log/copy-${node}-%j.out" --error="/vulcanscratch/gihan/audio-relatedwork/mips/log/copy-${node}-%j.err"
    COUNT=$((COUNT + 1))
done < "$NODE_LIST"

echo ""
echo "Done. Submitted ${COUNT} jobs."
