#!/usr/bin/env bash
set -euo pipefail

# Check the size of /fs/nexus-projects/AudioWorldModel/data/
# See whether /scratch0 or /scratch1 has gihan folder, with gihan/data folder with same size.
# If not, see which of the two has enough space to copy the data to.
# If /scratch0 has enough space, copy the data to /scratch0/gihan/data.
# If /scratch1 has enough space, copy the data to /scratch1/gihan/data.
# If neither has enough space, error out.

SRC="/fs/nexus-projects/AudioWorldModel/data"
DEST_NAME="gihan/data"

# ---- measure source size (in KB) ----
echo "Calculating size of ${SRC} ..."
SRC_SIZE_KB=$(du -sk "$SRC" | awk '{print $1}')
SRC_SIZE_MB=$((SRC_SIZE_KB / 1024))
echo "Source size: ${SRC_SIZE_MB} MB (${SRC_SIZE_KB} KB)"

# ---- helper: check if a scratch destination already has a complete copy ----
check_existing() {
    local scratch="$1"
    local dest="${scratch}/${DEST_NAME}"
    if [ -d "$dest" ]; then
        local dest_size_kb
        dest_size_kb=$(du -sk "$dest" | awk '{print $1}')
        # allow 1% tolerance
        local diff=$(( SRC_SIZE_KB - dest_size_kb ))
        if [ "${diff#-}" -le $((SRC_SIZE_KB / 100)) ]; then
            echo "Destination ${dest} already exists with matching size (${dest_size_kb} KB vs ${SRC_SIZE_KB} KB). Nothing to do."
            return 0
        else
            echo "Destination ${dest} exists but size differs (${dest_size_kb} KB vs ${SRC_SIZE_KB} KB). Will re-copy."
            return 1
        fi
    fi
    return 1
}

# ---- helper: check available space on a scratch drive ----
has_enough_space() {
    local scratch="$1"
    if [ ! -d "$scratch" ]; then
        return 1
    fi
    local avail_kb
    avail_kb=$(df -k "$scratch" | tail -1 | awk '{print $4}')
    # require source size + 5% headroom
    local required_kb=$(( SRC_SIZE_KB + SRC_SIZE_KB / 20 ))
    if [ "$avail_kb" -ge "$required_kb" ]; then
        echo "${scratch} has ${avail_kb} KB available (need ${required_kb} KB). OK."
        return 0
    else
        echo "${scratch} has ${avail_kb} KB available but need ${required_kb} KB. Not enough."
        return 1
    fi
}

# ---- helper: perform the copy ----
do_copy() {
    local scratch="$1"
    local dest="${scratch}/${DEST_NAME}"
    mkdir -p "$dest"

    # Step 1: copy everything except .mp4 files
    echo ""
    echo "[Step 1/2] Copying non-.mp4 files: ${SRC} -> ${dest} ..."
    rsync -ah --progress --exclude='*.mp4' "$SRC/" "$dest/"
    echo "[Step 1/2] Done."

    echo "Setting read permissions for all users on ${dest} ..."
    chmod -R a+rX "$dest"

    # Step 2: copy .mp4 files
    echo ""
    echo "[Step 2/2] Copying .mp4 files: ${SRC} -> ${dest} ..."
    rsync -ah --progress --include='*/' --include='*.mp4' --exclude='*' "$SRC/" "$dest/"
    echo "[Step 2/2] Done."

    echo "Setting read permissions for all users on ${dest} ..."
    chmod -R a+rX "$dest"

    echo ""
    echo "All data copied to ${dest}"
}

# ---- main logic ----

# First check if either scratch already has a complete copy
for scratch in /scratch0 /scratch1; do
    if check_existing "$scratch"; then
        exit 0
    fi
done

echo ""

# Neither has a complete copy -- find one with enough space
for scratch in /scratch0 /scratch1; do
    if has_enough_space "$scratch"; then
        do_copy "$scratch"
        exit 0
    fi
done

echo ""
echo "ERROR: Neither /scratch0 nor /scratch1 has enough space to copy the data."
echo "Source size: ${SRC_SIZE_MB} MB"
exit 1
