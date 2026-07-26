#!/usr/bin/env bash
#
# One-time per-user setup for the ABINIT–AbiPy speedrun tutorial on CEMDI.
# Run from the repository root:
#
#   bash Setup/setup_cemdi.sh

set -euo pipefail

say() {
    printf '\n>>> %s\n' "$*"
}

backup_if_present() {
    local target="$1"
    if [[ -e "$target" ]]; then
        local backup="${target}.before-cemdi-tutorial"
        cp -a "$target" "$backup"
        printf '    Backed up %s to %s\n' "$target" "$backup"
    fi
}

say "Loading the tested CEMDI software environment"

module use /project/def-sponsor00/shared/modules
module load abinit/10.8.2
module load python/3.12.4
module load abipy/1.0.0

REAL_MPIRUN="$(command -v mpirun)"
PYTHON_EXE="$(command -v python)"
ABINIT_EXE="$(command -v abinit)"

if [[ -z "$REAL_MPIRUN" || -z "$PYTHON_EXE" || -z "$ABINIT_EXE" ]]; then
    echo "ERROR: Failed to locate mpirun, Python, or ABINIT after loading modules." >&2
    exit 1
fi

say "Installing the reusable terminal environment"

CEMDI_ENV="$HOME/.cemdi.sh"
backup_if_present "$CEMDI_ENV"

cat > "$CEMDI_ENV" <<'EOF'
# ABINIT–AbiPy speedrun tutorial environment on CEMDI.
export OMP_NUM_THREADS=1
module use /project/def-sponsor00/shared/modules
module load abinit/10.8.2
module load python/3.12.4
module load abipy/1.0.0
EOF

BASHRC="$HOME/.bashrc"
SOURCE_LINE='source "$HOME/.cemdi.sh" >/dev/null 2>&1'
touch "$BASHRC"
if ! grep -qF "$SOURCE_LINE" "$BASHRC"; then
    {
        printf '\n# ABINIT–AbiPy speedrun tutorial environment\n'
        printf '%s\n' "$SOURCE_LINE"
    } >> "$BASHRC"
fi

say "Installing the CEMDI MPI launcher"

TUTORIAL_USER_DIR="$HOME/.local/share/abinit-speedrun"
BIN_DIR="$TUTORIAL_USER_DIR/bin"
MPI_WRAPPER="$BIN_DIR/mpirun"
mkdir -p "$BIN_DIR"

cat > "$MPI_WRAPPER" <<EOF
#!/usr/bin/env bash
exec "$REAL_MPIRUN" --oversubscribe "\$@"
EOF
chmod u+x "$MPI_WRAPPER"

say "Installing the 8-core AbiPy task manager"

ABIPY_CONFIG_DIR="$HOME/.abinit/abipy"
MANAGER_FILE="$ABIPY_CONFIG_DIR/manager.yml"
SCHEDULER_FILE="$ABIPY_CONFIG_DIR/scheduler.yml"
mkdir -p "$ABIPY_CONFIG_DIR"

backup_if_present "$MANAGER_FILE"
backup_if_present "$SCHEDULER_FILE"

cat > "$MANAGER_FILE" <<EOF
hardware: &hardware
  num_nodes: 1
  sockets_per_node: 1
  cores_per_socket: 8
  mem_per_node: 30 GB

job: &job
  mpi_runner: $MPI_WRAPPER
  modules: []
  shell_env:
    OMP_NUM_THREADS: "1"
  pre_run: []

qadapters:
  - priority: 1
    queue:
      qtype: shell
      qname: localhost
    limits:
      timelimit: 1:00:00
      max_cores: 8
    hardware: *hardware
    job: *job
EOF

cat > "$SCHEDULER_FILE" <<'EOF'
max_njobs_inqueue: 2
max_ncores_used: 8
seconds: 10
EOF

say "Registering the CEMDI AbiPy 1.0 Jupyter kernel"

KERNEL_LAUNCHER="$BIN_DIR/cemdi-abipy-kernel"
KERNEL_DIR="$HOME/.local/share/jupyter/kernels/cemdi-abipy"
KERNEL_JSON="$KERNEL_DIR/kernel.json"
mkdir -p "$KERNEL_DIR"

cat > "$KERNEL_LAUNCHER" <<'EOF'
#!/usr/bin/env bash
source "$HOME/.cemdi.sh" >/dev/null 2>&1
exec python -m ipykernel_launcher "$@"
EOF
chmod u+x "$KERNEL_LAUNCHER"

cat > "$KERNEL_JSON" <<EOF
{
  "argv": [
    "$KERNEL_LAUNCHER",
    "-f",
    "{connection_file}"
  ],
  "display_name": "CEMDI AbiPy 1.0",
  "language": "python"
}
EOF

say "Checking Python and ABINIT"

source "$CEMDI_ENV" >/dev/null 2>&1

python - <<'PY'
import sys
import numpy
import abipy

print("Python", sys.version.split()[0])
print("NumPy", numpy.__version__)
print("AbiPy", abipy.__version__)
PY

printf 'ABINIT executable: %s\n' "$ABINIT_EXE"
"$MPI_WRAPPER" -np 1 abinit --version

say "Checking the AbiPy configuration"

ABICHECK_LOG="/tmp/cemdi-abicheck-${USER}.log"
if ! abicheck.py >"$ABICHECK_LOG" 2>&1; then
    cat "$ABICHECK_LOG"
    echo "ERROR: abicheck.py failed." >&2
    exit 1
fi

tail -20 "$ABICHECK_LOG"

if ! grep -q "Abipy requirements are properly configured" "$ABICHECK_LOG"; then
    echo "ERROR: AbiPy did not report a valid configuration." >&2
    exit 1
fi

say "Setup completed successfully"

cat <<'EOF'

Return to JupyterLab and refresh the browser page if necessary.
For every tutorial notebook, select:

    Kernel -> Change Kernel -> CEMDI AbiPy 1.0

Then begin with Notebooks/0-Setup.ipynb.
EOF
