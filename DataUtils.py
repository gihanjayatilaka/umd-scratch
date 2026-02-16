def resolve_data_root():
    for scratch in ("/scratch0/gihan/data", "/scratch1/gihan/data"):
        if os.path.isdir(scratch):
            print(f"[Datasets_Base] Using data root: {scratch}")
            return scratch
    fallback = "/fs/nexus-projects/AudioWorldModel/data"
    print(f"[Datasets_Base] Using data root: {fallback}")
    return fallback

DATA_ROOT = resolve_data_root()
