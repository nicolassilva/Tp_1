#!/bin/bash

#2 arguments positionnels: 16S_workflow.sh dossier_reads_bruts dossier_sortie
dossier_reads_bruts=$1
dossier_sortie=$2

mkdir -p $dossier_sortie/av_trim
mkdir -p $dossier_sortie/ap_trim
mkdir -p $dossier_sortie/alien_trim
mkdir -p $dossier_sortie/vsearch

gunzip $dossier_reads_bruts/*.gz

fastqc $dossier_reads_bruts/*.fastq -o $dossier_sortie/av_trim/

./soft/JarMaker.sh AlienTrimmer.java
 
for i in $(ls $dossier_reads_bruts/*R1.fastq)
do
	nameR1=$i
	nameR2=$(echo $i | sed 's/R1/R2/g')
	nameR3=$(echo $i | sed 's/R1//g')
	samplename=$(echo $i | cut -d/ -f 2 | cut -d_ -f 1)

	java -jar soft/AlienTrimmer.jar -if $nameR1 -ir $nameR2 -c databases/contaminants.fasta -q 20 -of $dossier_sortie/alien_trim/$nameR1.at.fq -or $dossier_sortie/alien_trim/$nameR2.at.fq -os $dossier_sortie/alien_trim/$nameR3.at.sgl.fq
	fastqc $dossier_sortie/alien_trim/$nameR1.at.fq $dossier_sortie/alien_trim/$nameR2.at.fq  -o $dossier_sortie/ap_trim/
	vsearch --fastq_mergepairs $dossier_sortie/alien_trim/$nameR1.at.fq --reverse $dossier_sortie/alien_trim/$nameR2.at.fq --fastaout $dossier_sortie/vsearch/$samplename.fasta --label_suffix "$s;sample=$samplename;" --fastq_minovlen 40 --fastq_maxdiffs 15

done

cat $dossier_sortie/vsearch/*.fasta | tr -d ' ' > $dossier_sortie/vsearch/clustering/amplicon.fasta

vsearch --derep_fulllength $dossier_sortie/vsearch/clustering/amplicon.fasta --output $dossier_sortie/vsearch/clustering/amplicon_dereplicated.fasta --sizeout
vsearch --fastx_filter $dossier_sortie/vsearch/clustering/amplicon_dereplicated.fasta --minsize 10 --fastaout $dossier_sortie/vsearch/clustering/amplicon_wo_singleton.fasta
vsearch --uchime_denovo $dossier_sortie/vsearch/clustering/amplicon_wo_singleton.fasta --chimeras $dossier_sortie/vsearch/clustering/amplicon_chimeras.fasta --nonchimeras $dossier_sortie/vsearch/clustering/amplicon_non_chimeras.fasta 
vsearch --cluster_size $dossier_sortie/vsearch/clustering/amplicon_non_chimeras.fasta --id 0.97 --centroids $dossier_sortie/vsearch/clustering/amplicon_cluster.fasta --relabel OTU_
vsearch --usearch_global $dossier_sortie/vsearch/clustering/amplicon.fasta --db $dossier_sortie/vsearch/clustering/amplicon_cluster.fasta --id 0.97 --otutabout $dossier_sortie/vsearch/clustering/otu_table.txt
vsearch --usearch_global $dossier_sortie/vsearch/clustering/amplicon.fasta --db databases/mock_16S_18S.fasta --id 0.90 --top_hits_only --userfields query+target --userout $dossier_sortie/vsearch/clustering/annotation_table.txt

sed '1iOTU\tAnnotation' -i $dossier_sortie/vsearch/clustering/annotation_table.txt
