# ABINIT–AbiPy Speedrun Tutorial on CEMDI

This guide prepares your CEMDI JupyterLab session for the ABINIT–AbiPy
speedrun tutorial. Complete the setup below **before opening the tutorial
notebooks**.

The setup has been tested on `cemdi.calculquebec.cloud` with:

- 8 CPU cores
- 30,000 MB of memory
- ABINIT 10.8.2
- AbiPy 1.0.0
- Python 3.12.4

## 1. Start JupyterLab

1. Sign in to `cemdi.calculquebec.cloud`.
2. Start a new JupyterLab session.
3. Request:

   | Resource | Value |
   |---|---:|
   | CPU cores | 8 |
   | Memory | 30,000 MB |
   | Session duration | 2 hours |

Do not use the smaller default allocation. Several tutorial flows run two
four-core ABINIT calculations concurrently.

## 2. Obtain a private working copy

Open **File → New → Terminal** in JupyterLab. Clone the tutorial repository
using the URL supplied by the instructor:

```bash
mkdir -p "$HOME/projects"
cd "$HOME/projects"
git clone <repository-url>
cd Abinit_speedrun_tutorial
```

If the repository has already been copied into your project space, simply
change into its top-level directory. This is the directory containing
`Notebooks/`, `Examples/`, `Setup/`, and `README.md`.

Use your own working copy. The notebooks create and sometimes remove
calculation directories such as `flow_gaas_convecut/`.

## 3. Run the CEMDI setup

From the repository root, run:

```bash
bash Setup/setup_cemdi.sh
```

The script performs the following user-level configuration:

1. Loads ABINIT 10.8.2, Python 3.12.4, and AbiPy 1.0.0.
2. creates `~/.cemdi.sh` and configures future terminals to source it;
3. installs an AbiPy manager limited to 8 cores and 30 GB;
4. limits the scheduler to two simultaneous four-core calculations;
5. installs a CEMDI-specific MPI launcher;
6. registers a user-level Jupyter kernel named **CEMDI AbiPy 1.0**; and
7. verifies the Python imports, ABINIT executable, and AbiPy configuration.

The script is safe to run again. Existing generated configuration files are
backed up before replacement.

The final output should include:

```text
Python 3.12.4
AbiPy 1.0.0
ABINIT 10.8.2
Abipy requirements are properly configured
Setup completed successfully
```

### Does every student need to create the kernel?

Yes. A kernel installed under one account is not normally visible in another
student's account. The setup script therefore creates a small user-level
kernel for each student.

This step would only become unnecessary if the CEMDI administrators installed
the same kernel globally for all workshop accounts. Running the setup script
would still be harmless.

## 4. Select the correct notebook kernel

After setup:

1. Return to the JupyterLab file browser.
2. Refresh the browser page if the new kernel is not immediately listed.
3. Open `Notebooks/0-Setup.ipynb`.
4. Select **Kernel → Change Kernel → CEMDI AbiPy 1.0**.

Use **CEMDI AbiPy 1.0** for every tutorial notebook.

Run this notebook cell as a final kernel check:

```python
import sys
import numpy
import abipy

print("Python:", sys.executable)
print("Python version:", sys.version.split()[0])
print("NumPy:", numpy.__version__)
print("AbiPy:", abipy.__version__)
```

Expected versions:

```text
Python version: 3.12.4
NumPy: 2.4.2
AbiPy: 1.0.0
```

Do not use the default Python kernel. On the tested CEMDI image, importing
AbiPy from the default kernel can terminate and restart the kernel because of
an incompatible compiled Python environment.

## 5. Follow the notebooks

Run the notebooks in this order:

1. `0-Setup.ipynb` — environment, structures, and pseudopotentials
2. `1-Task_to_flow.ipynb` — silicon SCF, NSCF, and flows
3. `2-Convergence_study.ipynb` — GaAs convergence and band structure
4. `3-Relaxation.ipynb` — AlN structural relaxation
5. `4-Phonons.ipynb` — MgO DFPT phonons and Anaddb
6. `5-Challenges.ipynb` — optional follow-up activities

In Notebook 0, the terminal installation checks are already handled by
`setup_cemdi.sh`. You may skip:

```python
wlib.shell_command("abicheck.py")
```

In Notebook 2, skip the following cell:

```python
Does it look okay?
```

It is a sentence that was accidentally marked as Python code.

## 6. Understand background flows

Commands such as:

```python
wlib.shell_command(
    "abirun.py flow_gaas_convecut scheduler",
    silent=True
)
```

start the scheduler in the background. Completion of the notebook cell does
**not** mean that the ABINIT calculations have finished.

Use the corresponding status cell repeatedly:

```python
wlib.shell_command(
    "abirun.py flow_gaas_convecut status"
)
```

Proceed to plotting only after the output contains:

```text
all_ok reached
```

If a flow is still `Submitted` or `Running`, wait approximately 10 seconds and
check again.

## 7. Important usage rules

- Do not launch `mpirun` manually from a notebook cell. Let AbiPy launch
  ABINIT through its task manager.
- It is fine to run diagnostic shell commands from a JupyterLab terminal.
- Do not start the same scheduler twice for one flow directory.
- Do not close the JupyterLab session while a flow is running.
- Do not move a built AbiPy flow directory. Rebuild it at the new location.
- Notebook cells may delete an existing flow directory before rebuilding it.
  Keep anything important outside the tutorial working copy.
- Select **CEMDI AbiPy 1.0** again if Jupyter switches kernels when opening a
  different notebook.

## 8. Expected runtime

The following timings were measured on CEMDI with 8 cores and 30 GB:

| Calculation | Measured time |
|---|---:|
| Small environment-validation flow | 31 s |
| GaAs cutoff convergence, 8 tasks | 113 s |
| GaAs k-point convergence, 6 tasks | 123 s |
| GaAs band structure | 140 s |
| AlN structural relaxation | 76 s |
| MgO DFPT phonon flow | 166 s |

The measured core calculations require roughly 10–15 minutes in total.
Notebook discussion, plotting, and instructor explanations should allow the
core tutorial to fit comfortably in a two-hour session.

The optional exercises are not included in this estimate:

- repeating the k-point study with `ecut=40`;
- relaxing a 31-atom aluminium-vacancy supercell;
- recomputing MgO phonons with Born effective charges; and
- the Notebook 5 challenges.

These activities are recommended for later exploration.

## 9. Troubleshooting

### Kernel repeatedly restarts when importing AbiPy

Confirm that the notebook is using **CEMDI AbiPy 1.0**, not the default
Python kernel. If the kernel is missing, rerun:

```bash
bash Setup/setup_cemdi.sh
```

Then refresh JupyterLab.

### “Not enough slots available”

This means the unmodified system `mpirun` was used. Verify the configured
runner:

```bash
grep mpi_runner ~/.abinit/abipy/manager.yml
```

It should point to:

```text
~/.local/share/abinit-speedrun/bin/mpirun
```

Rerun the setup script if it does not.

### A flow appears to run forever

Check its status:

```bash
abirun.py FLOW_DIRECTORY status
```

Then inspect errors:

```bash
find FLOW_DIRECTORY -name run.err -size +0c -print -exec tail -40 {} \;
```

Do not assume that an unchanged `Running` status means ABINIT is still using
the CPUs; inspect the error files.

### Flow directory already exists

Many notebook cells deliberately remove an old directory. If working from a
standalone script, rename or archive valuable output before removing anything.

### Setup validation fails

Run the following in a JupyterLab terminal and send the output to the
instructor:

```bash
source ~/.cemdi.sh
python -c "import sys, numpy, abipy; print(sys.version); print(numpy.__version__); print(abipy.__version__)"
command -v abinit
abicheck.py
```

## 10. Further reading

- [ABINIT documentation](https://docs.abinit.org/)
- [AbiPy documentation](https://abinit.github.io/abipy/)
- [AbiPy Book](https://abinit.github.io/abipy_book/intro.html)

This CEMDI setup guide supplements the original tutorial documentation.
Please retain the tutorial's original `LICENSE` and attribution when sharing
or modifying the material.
