#!/bin/bash
#SBATCH  -A emberson.prj
#SBATCH --job-name="gaudi_step1"
#SBATCH  -p short
#SBATCH --mem=50GB
#SBATCH --out /well/emberson/users/hma817/projects/MCPS_PRS_training/04_PRS_training/4.GAUDI_test/out/step1.out
	
CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data
local_ancestry_dir=$genotype_files/local_ancestry_rfmix
vcf_data=$genotype_files/vcf
software_dir=$CURDIR/Software/GAUDI
gwas_info=$CURDIR/external_data/GWAS_sources
out_dir=$CURDIR/Training_data/PRS/4.GAUDI_test


module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate
conda activate vcf_tools_env
chr=1

	while read chunk; do
	echo $chunk
		start_pos=$(( ($chunk - 1)*10*1000000 ))
		end_pos=$(( ($chunk)*10*1000000 ))

		$software_dir/py_vcf_to_la.py \
			--local-ancestry $local_ancestry_dir/merged_output_$chr.msp.tsv.gz \
			--vcf $vcf_data/mcps_subset_$chr.vcf.gz \
			--include $gwas_info/cc4d_p0.05.txt \
			--la-dosage-threshold 5 \
			--chr $chr  \
			--pos-start $start_pos --pos-stop $end_pos  \
			--out $out_dir/test_out_chr$chr_chunk${chunk}
	done < <( awk -v chr=$chr '$1==chr { print $2 }' $software_dir/data/chunk_list)

	# module load R/4.2.1-foss-2022a
	# Rscript 	$software_dir/merge_la_dosage.R $software_dir/data
	# 
	# 
	# Rscript $software_dir/fit_cv_fused_lasso.R \
	# 	--gaudi-path $software_dir \
	# 	--gwas $software_dir/data/GWAS_chr22_sim.regenie \
	# 	--gwas-col-id ID --gwas-col-p LOG10P --gwas-log-p TRUE \
	# 	--la $software_dir/data/test_out_allChr.la_dosage.mtx.gz \
	# 	--col $software_dir/data/test_out_allChr.la_dosage.colnames \
	# 	--row $software_dir/data/test_out_allChr.la_dosage.rownames \
	# 	--pheno $software_dir/data/test.pheno --pheno-name pheno --pheno-iid FID \
	# 	--start-p-exp -1 --end-p-exp -5 \
	# 	--seed 2022 --sparsity FALSE \
	# 	--out $software_dir/data/test_p1_5_model
		
	# Rscript $software_dir/apply_GAUDI.R \
	# 	--gaudi-path $software_dir \
	# 	--model $software_dir/data/test_p5_50_model.best_list.RDS \
	# 	--target-la-dir $software_dir/data/ \
	# 	--out $software_dir/data/test_self_fit