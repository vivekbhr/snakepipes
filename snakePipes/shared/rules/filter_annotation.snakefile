## make standard annotation

if genes_gtf.lower().find("gencode")>=0:
    rule create_annotation_bed:
        input:
            gtf = genes_gtf
        output:
            bed_annot = "Annotation/genes.annotated.bed"
        conda: CONDA_RNASEQ_ENV
        shell:
            "join -t $'\t' -o auto --check-order -1 4 -2 2 "
            "<(gtfToGenePred -ignoreGroupsWithoutExons {input.gtf} /dev/stdout | genePredToBed /dev/stdin /dev/stdout | tr ' ' $'\t' | sort -k4,4) "
            """ <(cat {input.gtf} | awk '$3~"transcript|exon"{{print $0}}' | tr -d "\\";" | """
            """ awk '{{pos=match($0,"tag.basic"); if (pos==0) basic="full"; else basic="basic"; """
            """ pos=match($0,"gene_[bio]*type.[^[:space:]]+"); gt=substr($0,RSTART,RLENGTH); """
            """ pos=match($0,"transcript_[bio]*type.[^[:space:]]+"); if (pos!=0) tt=substr($0,RSTART,RLENGTH); else tt="transcript_type NA"; """
            """ pos=match($0,"transcript_support_level.[^[:space:]]+"); if (pos!=0) tsl=substr($0,RSTART,RLENGTH);else tsl="transcript_support_level NA"; """
            """ pos=match($0,"[[:space:]]level.[^[:space:]]*"); if (pos!=0) lvl=substr($0,RSTART,RLENGTH);else lvl="level NA"; """
            """ pos=match($0,"gene_id.[^[:space:]]*"); gid=substr($0,RSTART,RLENGTH); """
            """ pos=match($0,"transcript_id.[^[:space:]]*"); tid=substr($0,RSTART,RLENGTH); """
            """ pos=match($0,"transcript_name.[^[:space:]]*"); tna=substr($0,RSTART,RLENGTH); """
            """ pos=match($0,"gene_name.[^[:space:]]*"); gna=substr($0,RSTART,RLENGTH); """
            """ OFS="\\t"; print tid,tna,tt,gid,gna,gt,"gencode",basic,tsl,lvl}}' | """
            """ tr " " "\\t" | sort | uniq | sort -k2,2) | """
            """ awk '{{$13=$13"\\t"$1; $4=$4"\\t"$1; OFS="\\t";print $0}}' | """
            """ cut --complement -f 1,14,16,18,20,22,24 > {output.bed_annot} """
elif genes_gtf.lower().find("ensembl")>=0:
    rule create_annotation_bed:
        input:
            gtf = genes_gtf
        output:
            bed_annot = "Annotation/genes.annotated.bed"
        conda: CONDA_RNASEQ_ENV
        shell:
            "join -t $'\t' -o auto --check-order -1 4 -2 2 "
            "<(gtfToGenePred {input.gtf} /dev/stdout | genePredToBed /dev/stdin /dev/stdout | tr ' ' $'\t' | sort -k4,4) "
            """ <(cat {input.gtf} | awk '$3=="transcript"{{print $0}}' | tr -d "\\";" | """
            """ awk '{{"""
            """ pos=match($0,"gene_biotype.[^[:space:]]+"); if (pos!=0) gt=substr($0,RSTART,RLENGTH); else gt="gene_biotype unknown_gene_biotype"; """
            """ pos=match($0,"transcript_biotype.[^[:space:]]+"); if (pos!=0) tt=substr($0,RSTART,RLENGTH); else tt="transcript_biotype unknown_tx_biotype"; """
            """ pos=match($0,"gene_id.[^[:space:]]*"); gid=substr($0,RSTART,RLENGTH); """
            """ pos=match($0,"transcript_id.[^[:space:]]*"); tid=substr($0,RSTART,RLENGTH); """
            """ pos=match($0,"transcript_name.[^[:space:]]*"); if (pos!=0) tna=substr($0,RSTART,RLENGTH); else tna=tid; """
            """ pos=match($0,"gene_name.[^[:space:]]*"); if (pos!=0) gna=substr($0,RSTART,RLENGTH); else gna=gid; """
            """ OFS="\\t"; print tid,tna,tt,gid,gna,gt}}' | """
            """ tr " " "\\t" | sort -k2,2) | """
            """ awk '{{$13=$13"\\t"$1; $4=$4"\\t"$1; OFS="\\t";print $0}}' | """
            """ cut --complement -f 1,14,16,18,20,22,24 > {output.bed_annot} """
## else the gtf format is not supported!!!


rule filter_annotation_bed:
    input:
        bed_annot = "Annotation/genes.annotated.bed"
    output:
        bed_filtered = "Annotation/genes.filtered.bed"
    params:
        pattern = str(filter_annotation or '\'\''),
        cmd = "Annotation/filter_command.txt"
    shell:
        """
        cat {input.bed_annot} | grep {params.pattern} > {output.bed_filtered};
        echo 'cat {input.bed_annot} | grep \'{params.pattern}\' > {output.bed_filtered}' > {params.cmd}
        """

rule annotation_bed2t2g:
    input:
        bed_annot = 'Annotation/genes.filtered.bed' 
    output:
        'Annotation/genes.filtered.t2g'
    shell:
        "cat {input.bed_annot} | cut -f 13-14,16 | awk '{{OFS=\"\t\"; print $1, $3, $2}}' > {output}"


rule annotation_bed2symbol:
    input:
        bed_annot = 'Annotation/genes.filtered.bed' 
    output:
        'Annotation/genes.filtered.symbol'
    shell:
        "cat {input.bed_annot} | cut -f 16,17 | sort | uniq | awk '{{OFS=\"\t\"; print $1, $2}}' > {output}"


rule annotation_bed2fasta:
    input:
        bed = "Annotation/genes.filtered.bed",
        genome_fasta = genome_fasta
    output:
        "Annotation/genes.filtered.fa"
    benchmark:
        "Annotation/.benchmark/annotation_bed2fasta.benchmark"
    threads: 1
    conda: CONDA_RNASEQ_ENV
    shell:
        "bedtools getfasta -name -s -split -fi {input.genome_fasta} -bed {input.bed} | sed 's/(.*)//g' > {output}"


rule annotation_bed2gtf_transcripts:
    input:
        bed = "Annotation/genes.filtered.bed"
    output:
        gtf = "Annotation/genes.filtered.transcripts.gtf"
    params:
        gtf_orig = genes_gtf
    shell:
        """
        cat {params.gtf_orig} | awk -v map_f={input.bed} 'BEGIN{{while(getline<map_f) MAP[$13]=$14}}
        {{if ($3!="transcript") next; pos=match($0,"transcript_id[[:space:]\\";]+([^[:space:]\\";]*)",tid); 
        if (tid[1] in MAP) print $0}}' > {output.gtf}
        """


rule annotation_bed2gtf:
    input:
        bed = "Annotation/genes.filtered.bed"
    output:
        gtf = "Annotation/genes.filtered.gtf"
    conda: CONDA_RNASEQ_ENV
    shell:
    	"""
        bedToGenePred {input.bed} stdout | awk -v map_f={input.bed} '
        BEGIN{{while (getline < map_f) MAP[$13]=$16}} {{OFS="\\t";print $0,"0",MAP[$1]}}' |
        genePredToGtf -utr file stdin stdout |
        grep -v "CDS" |
        awk -v map_f={input.bed} '
        BEGIN{{while (getline < map_f) MAP[$16]=$17}}
        {{pos=match($0,"gene_name[[:space:]]*[^[:space:]]*");
        gna=substr($0,RSTART,RLENGTH);
        pre=substr($0,1,RSTART-1);
        match(gna,"gene_name[[:space:]\\";]+([^[:space:]\\";]*)",a);
        print pre"gene_name \\""MAP[a[1]]"\\";"}}' > {output.gtf}
        """
