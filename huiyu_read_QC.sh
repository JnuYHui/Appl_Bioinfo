#!/bin/bash
echo "script start: download and initial sequencing read quality control"
date

module whatis sra-tools

module load sra-tools

fastq-dump -X10 --readids --gzip --outdir data/sra_fastq/ --disable-multithreading --split-e ERR6913156

zcat data/sra_fastq/ERR6913156_1.fastq.gz

cat analyses/huiyu_run_accession.txt |srun --cpus-per-task=1 --time=00:30:00 xargs fastq-dump --readids --gzip --outdir data/sra_fastq/ --disable-multithreading --split-e

seqkit stats data/sra_fastq/*

sqlite3 -batch /shared/projects/2314_medbioinfo/pascal/central_database/sample_collab.db "select run_accession from sample_annot left join sample2bioinformatician using(patient_code) where username='huiyu';" -noheader -csv analyses/huiyu_run_accession.txt

for FILE in data/sra_fastq/*; do zcat $FILE | seqkit rmdup -s -i -o data/clean_sra_fq/clean_data/$FILE -d data/clean_sra_fq/duplicated/$FILE -D dup_ditail_data/$FILE.txt

srun --cpus-per-task=2 --time=00:30:00 xargs -I{} -a ./analysis/huiyu_run_accessions.txt fastqc --outdir ./fastqc/ --threads 2 --noextract ./data/sra_fastq/{}_1.fastq.gz ./data/sra_fastq/{}_2.fastq.gz

scp huiyu@core.cluster.france-bioinformatique.fr:/shared/projects/2314_medbioinfo/hui/MedBioinfo23/analyses/fastqc/*.html ~/PhdCourse/2023-Appl-Bioinfo
#There is no adaptor shown from the last graph in the report

srun --cpus-per-task=2 flash2 --threads=2 -z --output-directory=../data/merged_pairs/ --output-prefix=ERR6913274.flash ../data/sra_fastq/ERR6913274_1.fastq.gz ../data/sra_fastq/ERR6913274_2.fastq.gz 2>&1 | tee -a your_username_flash2.log 

srun --cpus-per-task=2 flash2 --threads=2 -z --output-directory=../data/merged_pairs/ --output-prefix=ERR6913274.flash \
../data/sra_fastq/ERR6913274_1.fastq.gz ../data/sra_fastq/ERR6913274_2.fastq.gz 2>&1 | tee -a your_username_flash2.log

srun --cpus-per-task=2 --time=00:30:00 xargs -a analyses/huiyu_run_accession.txt -n 1 -I{} flash2 --threads=2 -z --output-directory=./data/merged_pairs --output-prefix={}.flash data/sra_fastq/{}_1.fastq.gz data/sra_fastq/{}_2.fastq.gz 2>&1 | tee -a huiyu_flash2.log 

date
echo "script end."