Setting up snakePipes
=====================

Unlike many other pipelines, setting up snakePipes is easy! All you need is a *conda* installation with *python3*.

Install conda with python3
--------------------------

Follow the instructions `here <https://conda.io/docs/user-guide/install/index.html>`__ to install either
miniconda or anaconda. A minimal version (miniconda) is enough for snakePipes. Get the miniconda installer `here <https://conda.io/miniconda.html>`__.

After installation, check your python path and version :

.. code-block:: bash

    $ which python
    $ /your_path/miniconda3/bin/python

    $ python --version # anything above 3.5 is ok!
    $ Python 3.6.5 :: Anaconda, Inc.

    $ conda --version # only for sanity check
    $ conda 4.5.8

Next, install snakePipes.


Install snakePipes
------------------

The easiest way to install snakePipes is via our conda channel. The following command also creates a
conda virtual environment named `snakePipes`, which you can then activate via `source activate snakePipes`.

.. code:: bash

    conda create -n snakePipes -c mpi-ie -c bioconda -c conda-forge snakePipes

Development installation
~~~~~~~~~~~~~~~~~~~~~~~~

If you wish to modify snakePipes you can install it via pip, using our `GitHub repository <https://github.com/maxplanck-ie/snakepipes>`__ or your own local modified clone.

.. code:: bash

    pip install --user --upgrade git+https://github.com/maxplanck-ie/snakepipes@develop

.. note:: There is a difference between installing via conda or installing via pip. The python installation from user's
          $PATH is ignored when installing via conda (first method) while is considered when installing via pip. You must use the `--develop` option later when you run `snakePipes createEnvs`.

.. note:: Using the --user argument would install the program into `~/.local/bin/`. So make sure to have it in your $PATH

Snakemake and pandas are installed as requirements. Ensure you have everything working by testing these commands:

.. code-block:: bash

    snakemake --help
    snakePipes --help


Inspect and modify the setup files
----------------------------------

After installation of snakePipes, all files required to configure it would be installed in a default path.
The path to these files can be displayed by running the following command:

.. code:: bash

    snakePipes info

This would show the locations of:

 * **defaults.yaml** See :ref:`conda`
 * **cluster.yaml** See :ref:`cluster`
 * **organisms/<organism>.yaml** : See :ref:`organisms`

You can modify these files to suite your needs before setting up the conda environments (see below).


.. _conda:

Install the conda environments
------------------------------

All the tools required for running various pipelines are installed via various conda repositories
(mainly bioconda). The following commands installs the tools and creates the respective conda environments.

.. code:: bash

    snakePipes createEnvs

.. note:: Creating the environments might take 1-2 hours. But it only has to be done once.

.. note::

    `snakePipes createEnvs` will also set the `snakemake_options:` line in the global snakePipes
    `defaults.yaml` files. If you have already modified this then use the `--keepCondaDir` option.

.. warning::
   If you installed with `pip` you must use the `--develop` option.

The place where the conda envs are created (and therefore the tools are installed) is defined in `snakePipes/defaults.yaml`
file on our GitHub repository. You can modify it to suite your needs.

Here are the content of *defaults.yaml*::

    snakemake_options: '--use-conda --conda-prefix /data/general/scratch/conda_envs'
    tempdir: /data/extended/

The `tempdir` path should be changed to a suitable directory that can hold the temporary files during pipeline execution.

.. note::

    Whenever you change the `snakemake_options:` line in `defaults.yaml`, you should run
    `snakePipes createEnvs` to ensure that the conda environments are then created.

Running `snakePipes createEnvs` is not strictly required, but facilitates multiple users using the same snakePipes installation.


.. _organisms:

Configure the organisms
-----------------------

For each organism of your choice, create a file called `shared/organisms/<organism>.yaml` and
fill the paths to the required files next to the corresponding yaml entry.

.. warning:: Do not edit the yaml keywords corresponding to each required entry.

An example from drosophila genome dm3 is below.

.. parsed-literal::

    genome_size: 142573017
    genome_fasta: "/data/repository/organisms/dm3_ensembl/genome_fasta/genome.fa"
    genome_index: "/data/repository/organisms/dm3_ensembl/genome_fasta/genome.fa.fai"
    genome_2bit: "/data/repository/organisms/dm3_ensembl/genome_fasta/genome.2bit"
    bowtie2_index: "/data/repository/organisms/dm3_ensembl/BowtieIndex/genome"
    hisat2_index: "/data/repository/organisms/dm3_ensembl/HISAT2Index/genome"
    bwa_index: "/data/repository/organisms/dm3_ensembl/BWAindex/genome.fa"
    known_splicesites: "/data/repository/organisms/dm3_ensembl/ensembl/release-78/HISAT2/splice_sites.txt"
    star_index: "/data/repository/organisms/dm3_ensembl/STARIndex/"
    genes_bed: "/data/repository/organisms/dm3_ensembl/Ensembl/release-78/genes.bed"
    genes_gtf: "/data/repository/organisms/dm3_ensembl/Ensembl/release-78/genes.gtf"
    blacklist_bed:
    ignore_forNorm: "U Uextra X XHet YHet dmel_mitochondrion_genome"

Not all files are required for all pipelines, but we recommend to keep all required files ready nevertheless.

.. _cluster:

Configure your cluster
----------------------

The `cluster.yaml` file is located under `shared/` and contains both the default memory requirements as well as two options passed to snakemake that control how jobs are submitted to the cluster and files are retrieved::

    snakemake_latency_wait: 300
    snakemake_cluster_cmd: module load slurm; SlurmEasy --mem-per-cpu {cluster.memory} --threads {threads} --log
    __default__:
        memory: 8G
    snp_split:
        memory: 10G

You can change the default per-core memory allocation if needed here. Importantly, the `snakemake_cluster_cmd` option must be changed to match your needs. Whatever command you specify must include a `{cluster.memory}` option and a `{threads}` option. You can specify other required options here as well. The `snakemake_latency_wait` value defines how long snakemake should wait for files to appear before throwing an error. The default of 300 seconds is typically reasonable when NFS is in use.
