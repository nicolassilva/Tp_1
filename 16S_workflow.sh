#!/bin/bash

#2 arguments positionnels: 16S_workflow.sh dossier_reads_bruts dossier_sortie
dossier_reads_bruts=$1
dossier_sortie=$2

mkdir -p $dossier_sortie/avant_trim
mkdir -p $dossier_sortie/apres_trim
mkdir -p $dossier_sortie/alien_trim/$dossier_reads_bruts

gunzip $dossier_reads_bruts/*.gz

fastqc $dossier_reads_bruts/*.fastq -o $dossier_sortie/avant_trim/
cd soft/
./JarMaker.sh AlienTrimmer.java
cd ..
for i in $(ls $dossier_reads_bruts/*R1.fastq)
do
	nameR1=$i
	nameR2=$(echo $i | sed 's/R1/R2/g')
	nameR3=$(echo $i | sed 's/R1//g')
	java -jar soft/AlienTrimmer.jar -if $nameR1 -ir $nameR2 -c databases/contaminants.fasta -q 20 -of $dossier_sortie/alien_trim/$nameR1.at.fq -or $dossier_sortie/alien_trim/$nameR2.at.fq -os $dossier_sortie/alien_trim/$nameR3.at.sgl.fq
	fastqc $dossier_sortie/alien_trim/$nameR1.at.fq $dossier_sortie/alien_trim/$nameR2.at.fq -o $dossier_sortie/apres_trim/
done
