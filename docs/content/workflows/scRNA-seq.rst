.. _scRNA-seq:

scRNA-seq
=========

What it does
------------

The scRNA-seq pipeline is intended to process CEL-Seq2 data, though it may be able to process some similar Drop-seq protocols. The general procedure involves 

1. moving cell barcodes and UMIs from read 1 into the read headers of read 2,
2. mapping read 2,
3. quantification at the single cell level. 

UMIs in the read headers are used to avoid counting PCR duplicates. A number of bigWig and QC plots (e.g., from `plotEnrichment`) are generated as well.

.. image:: ../images/scRNAseq_pipeline.png

Input requirements
------------------

The primary input requirement is a directory of paired-end fastq files. In addition, if you do not wish to use the default list of cell-barcodes you must then supply your own.

Cell barcodes
~~~~~~~~~~~~~

The format of the cell barcodes file is shown below. Note that the default file is included in the snakePipes source code under `snakePipes/workflows/scRNAseq`. This file is automatically used if you leave :code:`barcode_file` empty.

::

    1       AGTGTC
    2       ACCATG
    3       GAGTGA
    4       CACTCA
    5       CATGTC
    6       ACAGGA
    7       GTACCA
    8       ACAGAC
    9       ACGTTG

The default cell barcodes are 192 hexamers listed in a file with the first column a cell number and the second the barcode sequence. 

Predefined cell barcodes are required right now. However it is planned to make this more generic in future workflow versions.

Configuration file
~~~~~~~~~~~~~~~~~~

The default configuration file is listed below and can be found in `snakePipes/workflows/scRNAseq/defaults.yaml`::

    pipeline: scrna-seq
    outdir:
    configfile:
    cluster_configfile:
    local: False
    max_jobs: 5
    ## directory with fastq files
    indir:
    ## preconfigured target genomes (mm9,mm10,dm3,...) , see /path/to/snakemake_workflows/shared/organisms/
    ## Value can be also path to your own genome config file!
    genome:
    ## FASTQ file extension (default: ".fastq.gz")
    ext: '.fastq.gz'
    ## paired-end read name extension (default: ["_R1", "_R2"])
    reads: ["_R1","_R2"]
    ## Number of reads to downsample from each FASTQ file
    downsample:
    ## Options for trimming
    trim: False
    trim_prg: cutadapt
    trim_options: -a A{'30'}
    ## further options
    filter_annotation: "-v -P 'decay|pseudogene' "
    barcode_file:
    barcode_pattern: "NNNNNNXXXXXX"
    split_lib: False
    cell_names:
    library_type: 1
    bw_binsize: 10
    verbose: False
    plot_format: png
    dnaContam: False

While some of these can be changed on the command line, you may find it useful to change `barcode_pattern` and `barcode_file` if you find that you need to change them frequently.

Barcode pattern
~~~~~~~~~~~~~~~

The scRNA-seq pipeline requires barcodes at 5' end of read 1. The default barcode_pattern takes the first 6 bases as UMI (NNNNNN) and the following 6 bases as cell barcode (XXXXXX).
If your read/barcode layout requires additional *'Don't care'* positions eg. before stretches of N one can indicate these with ``.``

Barcode file
~~~~~~~~~~~~~~~

Only specify a file if you use other than the default CEL-seq2 barcodes.


Trimming
~~~~~~~~

It is recommended to use the :code:`--trim` option as this uses cutadapt to trim remaining adapters *and* poly-A tails from read 2 (see defaults for `--trim_options`).       

Pseudogene filter
~~~~~~~~~~~~~~~~~

As default, transcripts or genes that contain that are related to biotypes like 'pseudogene' or 'decay' are filtered out before tag counting (see 
:code:`--filter_annotation` default).
Here we assume you provide eg. a gencode or ensemble annotation file (via genes_gtf in the organism configuration yaml) that contains this information.
  
Library Type
~~~~~~~~~~~~~~~

The CEL-seq2 protocol produces reads where read 2 maps in sense direction (:code:`library_type: 1`). After barcodes are transferred to read 2, the workflow continues in single-end mode.

Split lib
~~~~~~~~~

This option you need in case a library contains only 96 instead of 192 cells.



Output structure
----------------

The following will be produced in the output directory::

    .
    ├── Annotation
    ├── bamCoverage
    ├── Counts
    │   ├── GSM2668205.umis.txt
    │   ├── GSM2668205.reads.txt
    │   ├── GSM2668205.raw_counts.txt
    │   ├── GSM2668205.corrected.txt
    │   ├── GSM2668205.featureCounts_summary.txt
    ├── deepTools_qc
    │   ├── bamPEFragmentSize
    │   ├── estimateReadFiltering
    │   └── plotEnrichment
    ├── FASTQ
    ├── FASTQ_barcoded
    ├── FastQC
    ├── multiQC
    ├── QC_report
    │   ├── data
    │   │   ├── GSM2668205.cellsum
    │   │   └── GSM2668205.libsum
    │   ├── QC_report.all_samples.libstats_pct.tsv
    │   ├── QC_report.all_samples.libstats_reads.tsv
    │   ├── QC_report.all_samples.plate_abs_transcripts.png
    │   ├── QC_report.all_samples.plate_cRPM.png
    │   ├── QC_report.all_samples.plate_cUPM.pdf
    │   └── QC_report.all_samples.reads_UMI_plot.pdf
    ├── Results
    │   ├── all_samples.gencode_genomic.coutt_merged.txt
    │   └── all_samples.used_cells.tsv
    ├── Sambamba
    │   ├── flagstat_report_all.tsv
    │   └── GSM2668205.markdup.txt
    └── STAR_genomic
        ├── GSM2668205.bam
        └── GSM2668205.bam.bai

The `Annotation` directory contains a filtered version of your original GTF file, with pseudogenes removed by default. 
The `bamCoverage` directory contains a bigwig track for each sample (not per cell!). This can be used eg. in IGV to check where your reads map in general.
The `Counts` directory contains 4 sets of counts: UMIs/feature/cell (.umis.txt), reads/feature/cell (.reads.txt), corrected number of UMIs/feature/cell (corrected.txt) and raw counts per cell per UMI per feature (raw_counts.txt). Of these, the values in corrected.txt should be used for further analysis and the others for quality control.
The `deeptools_qc` directory contains additional QC reports and plots. The `FASTQC` directory can be used to verify eg. the barcode layout of read 1.
The `QC_report` directory contains additional QC stats as tables and plots.    

Results
--------------

- Main result: the genes per cell count table with poisson-corrected counts can be found under :code:`Results/all_samples.gencode_genomic.corrected_merged.csv`
- corresponding annotation files are: `Annotation/genes.filtered.bed` and `Annotation/genes.filtered.gtf`, respectively
- the folders `QC_report`, `FASTQC`, `deeptools_qc` and `multiQC` contain various QC tables and plots.  
- `Sambamba` and `STAR_genomic` directories contain the output file from duplicate marking and genomic alignments, respectively


Example images
--------------

There are a number of QC images produced by the pipeline:

.. image:: ../images/scRNAseq_UMI_plot.png

This figure plots the number of UMIs on transcripts per cell vs the number of reads aligning to transcripts. These should form a largely straight line, with the slope indicating the level of PCR duplication.

.. image:: ../images/scRNAseq_plate_abs_transcript.png

This figure shows the distribution of the number of UMIs across the single cells. Each block is a single cell and the color indicates the number of UMIs assigned to it. This is useful for flagging outlier cells.
Note: the layout corresponds to half of a 384-well plate as this is used usually for CEL-seq2. The plot can also help to see biases corresponding to the well-plate.

Command line options
--------------------

.. argparse::
    :func: parse_args
    :filename: ../snakePipes/workflows/scRNAseq/scRNAseq
    :prog: scRNAseq
    :nodefault:
