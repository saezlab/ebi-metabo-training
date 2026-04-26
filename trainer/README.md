# `trainer/` — for trainers only

Internal scripts for managing the metabo2026 training infrastructure.
Participants don't need anything in here.

## Scripts

| Script              | What it does                                                                |
|---------------------|-----------------------------------------------------------------------------|
| `build_rlib.sh`     | On `beauty`: install all R deps into a fresh user library, then tar it.     |
| `upload_rlib.sh`    | rsync the resulting tarball to `static.omnipathdb.org/metabo2026/`.         |
| `install-nix.sh`    | NixOS-friendly install path (`env/install.R` redirects here on NixOS).      |
| `vm_smoke_test.sh`  | Reproduce the X11 font bug in a clean Docker container, verify the fix.    |
| `colab_smoke_test.ipynb` | A bare notebook to run on Colab to confirm both halves work end-to-end. |

## Typical workflow before a session

```bash
# 1. On `beauty`: regenerate the RLIB tarball with current package versions.
ssh -p2323 omnipath@omnipathdb.org
cd ~/teaching/metabo2026/repo
trainer/build_rlib.sh

# 2. Upload to the public static host.
trainer/upload_rlib.sh

# 3. Locally: confirm Docker reproduction + fix.
trainer/vm_smoke_test.sh

# 4. Optionally: open trainer/colab_smoke_test.ipynb in a fresh Colab and run.
```
