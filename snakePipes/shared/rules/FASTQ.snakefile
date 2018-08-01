

if downsample:
    if paired:
        rule FASTQdownsample:
            input:
                r1 = indir+"/{sample}"+reads[0]+".fastq.gz",
                r2 = indir+"/{sample}"+reads[1]+".fastq.gz"
            output:
                r1 = "FASTQ/{sample}"+reads[0]+".fastq.gz",
                r2 = "FASTQ/{sample}"+reads[1]+".fastq.gz"
            params:
                num_reads = downsample
            benchmark:
                "FASTQ/.benchmark/FASTQ_downsample.{sample}.benchmark"
            threads: 10
            conda: CONDA_SHARED_ENV
            shell: """
                seqtk sample -s 100 {input.r1} {params.num_reads} | pigz -p {threads} -9 > {output.r1}
                seqtk sample -s 100 {input.r2} {params.num_reads} | pigz -p {threads} -9 > {output.r2}
                """
    else:
        rule FASTQdownsample:
            input:
                indir+"/{sample}.fastq.gz"
            output:
                fq = "FASTQ/{sample}.fastq.gz",
            threads: 12
            params:
                num_reads = downsample
            conda: CONDA_SHARED_ENV
            shell: """
                seqtk sample -s 100 {input} {params.num_reads} | pigz -p {threads} -9 > {output}
                """
else:
    rule FASTQ:
        input:
            indir+"/{sample}{read}.fastq.gz"
        output:
            "FASTQ/{sample}{read}.fastq.gz"
        shell:
            "( [ -f {output} ] || ln -s -r {input} {output} ) && touch -h {output}"
