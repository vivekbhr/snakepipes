## function to get the name of the samplesheet and extend the name of the folder DESeq2 to DESeq2_[name]
def get_outdir(folder_name):
    sample_name = os.path.splitext(os.path.basename(str(sample_info)))[0]
    return("{}_{}".format(folder_name, sample_name))

## DESeq2 (on featureCounts)
rule DESeq2:
    input:
        counts_table = lambda wildcards : "featureCounts/counts_allelic.tsv" if 'allelic-mapping' in mode else "featureCounts/counts.tsv",
        sample_info = sample_info,
        symbol_file = "Annotation/genes.filtered.symbol" #get_symbol_file
    output:
        "{}/DESeq2.session_info.txt".format(get_outdir("DESeq2"))
    benchmark:
        "{}/.benchmark/DESeq2.featureCounts.benchmark".format(get_outdir("DESeq2"))
    params:
        script=os.path.join(maindir, "shared", "rscripts", "DESeq2.R"),
        outdir = get_outdir("DESeq2"),
        fdr = 0.05,
        importfunc = os.path.join(maindir, "shared", "rscripts", "DE_functions.R"),
        allele_info = lambda wildcards : 'TRUE' if 'allelic-mapping' in mode else 'FALSE',
        tx2gene_file = 'NA'
    log:
        out = "DESeq2.out",
        err = "DESeq2.err"
    conda: CONDA_RNASEQ_ENV
    shell:
        "cd {params.outdir} && "
        "Rscript {params.script} "
        "{input.sample_info} " # 1
        "../{input.counts_table} " # 2
        "{params.fdr} " # 3
        "../{input.symbol_file} " # 4
        "{params.importfunc} " # 5
        "{params.allele_info} " # 6
        "{params.tx2gene_file} " # 7
        " > {log.out} 2> {log.err}"


## DESeq2 (on Salmon)
rule DESeq2_Salmon:
    input:
        counts_table = "Salmon/counts.tsv",
        sample_info = sample_info,
        tx2gene_file = "Annotation/genes.filtered.t2g",
        symbol_file = "Annotation/genes.filtered.symbol" #get_symbol_file
    output:
        "{}/DESeq2.session_info.txt".format(get_outdir("DESeq2_Salmon"))
    benchmark:
        "{}/.benchmark/DESeq2.Salmon.benchmark".format(get_outdir("DESeq2_Salmon"))
    params:
        script=os.path.join(maindir, "shared", "rscripts", "DESeq2.R"),
        outdir = get_outdir("DESeq2_Salmon"),
        fdr = 0.05,
        importfunc = os.path.join(maindir, "shared", "rscripts", "DE_functions.R"),
        allele_info = 'FALSE',
        tx2gene_file = "Annotation/genes.filtered.t2g"
    log:
        out = "DESeq2_Salmon.out",
        err = "DESeq2_Salmon.err"
    conda: CONDA_RNASEQ_ENV
    shell:
        "cd {params.outdir} && "
        "Rscript {params.script} "
        "{input.sample_info} " # 1
        "../{input.counts_table} " # 2
        "{params.fdr} " # 3
        "../{input.symbol_file} " # 4
        "{params.importfunc} " # 5
        "{params.allele_info} " # 6
        "../{input.tx2gene_file} " # 7
        " > {log.out} 2> {log.err}"
