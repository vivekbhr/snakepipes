## sleuth (on Salmon)
rule sleuth_Salmon:
    input:
        quant_files = expand("Salmon/{sample}/abundance.h5", sample=samples),
        t2g = 'Annotation/genes.filtered.t2g',
        sample_info = sample_info
    output:
        "sleuth/so.rds"
    benchmark:
        "sleuth/.benchmark/sleuth.Salmon.benchmark"
    params:
        script=os.path.join(maindir, "shared", "rscripts", "sleuth.R"),
        indir = "Salmon",
        outdir = "sleuth",
        fdr = 0.05,
    log:
        out = "sleuth/logs/sleuth.out",
        err = "sleuth/logs/sleuth.err"
    conda: CONDA_RNASEQ_ENV
    shell:
        "cd {params.outdir} && "
        "Rscript {params.script} "
        "{input.sample_info} "
        "../{params.indir} "
        "../{params.outdir} "
        "{params.fdr} "
        "../{input.t2g} "
        "> {log.out} 2> {log.err}"
