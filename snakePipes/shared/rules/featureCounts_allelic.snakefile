
## featurecounts (paired options are inserted conditionally)

rule featureCounts_allele:
    input:
        gtf = "Annotation/genes.filtered.gtf",
        bam = "allelic_bams/{sample}.allele_flagged.sorted.bam",
        allele1 = "allelic_bams/{sample}.genome1.sorted.bam",
        allele2 = "allelic_bams/{sample}.genome2.sorted.bam"
    output:
        'featureCounts/{sample}.allelic_counts.txt'
    params:
        libtype = library_type,
        paired_opt = lambda wildcards: "-p -B " if paired else "",
        opts = config["featurecounts_options"],
    log:
        out = "featureCounts/{sample}.out",
        err = "featureCounts/{sample}.err"
    threads: 8
    conda: CONDA_RNASEQ_ENV
    shell:
        " featureCounts"
        " {params.paired_opt}{params.opts}"
        " -T {threads}"
        " -s {params.libtype}"
        " -a {input.gtf}"
        " -o {output}"
        " --tmpDir ${{TMPDIR}}"
        " {input.bam} {input.allele1} {input.allele2} > {log.out} 2> {log.err}"

rule merge_featureCounts:
    input:
        expand("featureCounts/{sample}.allelic_counts.txt", sample=samples)
    output:
        "featureCounts/counts_allelic.tsv"
    conda: CONDA_RNASEQ_ENV
    shell:
        "Rscript "+os.path.join(maindir, "shared", "rscripts", "merge_featureCounts.R")+" {output} {input}"
