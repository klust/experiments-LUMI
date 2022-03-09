# Running the tests

-   Create a directory in the scratch space to run the tests

-   Untar the file with all data needed for GROMACS.

    ```bash
    tar -xf $HOME/SAVE/LUMI_test_Olivier.tar.gz
    ```

-   Link to the `prep_u-*` and `prep_b-*` scripts that will be used
    as well as the scripts to start a bunch of jobs, e.g.,

    ```bash
    /bin/rm -f prep_u.py prep_b.py
    ln -s $HOME/experiments-LUMI/Olivier/prep_u-test_202203.py prep_u.py
    ln -s $HOME/experiments-LUMI/Olivier/prep_b-test_202203.py prep_b.py
    ln -s $HOME/experiments-LUMI/Olivier/start_u.sh
    ln -s $HOME/experiments-LUMI/Olivier/start_b.sh
    ```

-   It is of course best to start with a simple test run.

    ```bash
    ./prep_u.py 1 1
    ./prep_b.py 1 1
    sbatch unbound1.slurm
    sbatch bound1.slurm
    ```

-   For running tests for a range of initial conditions:

    ```bash
    ./prep_u.py 2 100
    ./start_u.sh 2 100
    ./prep_b.py 2 100
    ./start_b.sh 2 100
    ```


## Instructions of the author

Input files:

-   amber99sb-ildn.ff : het force field
-   topol_inx.itp : parameters voor het ligand
-   bound.* en unbound.* : input files voor de gebonden en ongebonden simulaties.

Al deze files zouden in de folder moeten staan vanwaar je de jobs lanceert.

Verder zijn er nog volgende 2 scripts:

-   prep_b.py
-   prep_u.py

Deze dienen om de scripts voor sbatch te genereren. Als je bv '$ prep_b.py 1 100' doet, worden de
scripts voor simulaties 1 tot 100 voor de gebonden state gemaakt. Deze kan je dan allemaal lanceren.
Wil je later extra gebonden simulaties lanceren, kan je de job scripts maken via '$ prep_b.py 101 200'.
Moest het format van het job script niet juist zijn, kan je deze ook makkelijk aanpassen in het
pythonscript.

De output wordt geprint in $SCRATCH/unbound_simNUMMER, waarbij NUMMER de nummer van de simulatie is
(dewelke gekozen is via het python script). Als de variabele $SCRATCH niet bestaat of niet juist is
voor LUMI, moet je deze nog wel even in de twee python scriptjes aanpassen. Verder heb ik volgende
modules ingeladen:

module load lumi/supported
module load GROMACS/2020.4-intel-2020a-PLUMED-2.6.4
