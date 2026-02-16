Written for SLURM

1. How to get info about nodes
```
sinfo -N --format="%N %G" > allNode.txt
```

2. Delete the lines that doesn't have good GPUs you need.

3. Change the copy-data-to-scratch.sh to match what data to be copied.

4. Run sbatch-all-nodes.sh

5. Change the DataUtils.py code to match your locations.