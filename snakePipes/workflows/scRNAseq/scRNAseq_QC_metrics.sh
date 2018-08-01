#!/bin/bash

dir_in=$1
dir_out=$2

dir_in=$(readlink -m $dir_in)

mkdir -p $dir_out/data

if test -z "$(find $dir_in/ -maxdepth 1 -name '*.featureCounts_summary.txt')"; then 

  for i in  $dir_in/*.cout{b,c}.csv; do 
        type=$(echo $i | sed 's/.*\///' | sed 's/.*\.\(cout.\)\.csv$/\1/'); ## type = "coutc" or "coutb"
        sample=$(echo $i | sed 's/.*\///' | sed 's/\.cout.\.csv$//'); ## sample name without ending
	echo $sample 1>&2;
	cat $i | awk -v sample=$sample -v type=$type '{
		if (NR==1) {cells = NF-1; next;}; 
		for (i=2;i<=NF;i++) COUNTS[i-1]+=$i;
	 }
 	END{
		#match(sample,"([^[:space:]\\.]+)\\.([^[:space:]\\.]+).csv",name)
		if (type~"coutc") print "sample\tcell_idx\tREADS_UNIQFEAT"; 
		else 	print "sample\tcell_idx\tUMI"; 	
		for (i=1;i<=cells;i++) {
			OFS="\t";print sample,i,COUNTS[i];
		}
	}' > $dir_out/data/$sample.$type.cellsum;
  done
  for i in  $dir_out/data/*.coutc.cellsum; do
	coutb=$(echo $i | sed 's/\.coutc\.cellsum$/\.coutb\.cellsum/')
	sample=$(echo $i | sed 's/.*\///' | sed 's/\.cout.\.cellsum$//'); ## sample name without ending
  	paste $i $coutb | cut -f1-3,6 > $dir_out/data/$sample.cellsum;
  done 
  rm $dir_out/data/*.cout{b,c}.cellsum;

else 
  for i in $dir_in/*.featureCounts_summary.txt; do
    out=$(echo $i | sed 's/.*\///' | sed 's/\.featureCounts_summary.txt//');
    cat $i | sed -n -e '/sample.cell_idx.READS/,/#LIB/{{/#LIB/d;p}}' > $dir_out/data/$out.cellsum;
    cat $i | grep "^#LIB" | tr -d "#" | sed -e 's/^/'$out'\t/' > $dir_out/data/$out.libsum;
   done
fi


#for i in  $dir_in/*cout{b,c}.csv; do 
# out=$(echo $i | sed 's/.*\///'); 
# out2=$(echo $out | sed 's/\.csv$//');
#	echo $out 1>&2;
# cat $i | awk -v file=$out '{if (NR==1) {next;}; for (i=2;i<=NF;i++) COUNTS[i-1]+=$i;} \
#  END{for (i=1;i<=192;i++){if (i<=96) sum1+=COUNTS[i];else sum2+=COUNTS[i];} if (sum1>sum2) offset=1; else offset=97; \
#      for (i=offset;i<offset+96;i++) {OFS="\t";print file,i,COUNTS[i];sum+=COUNTS[i];}}' >$dir_out/data/$out.cellsum;
#done

