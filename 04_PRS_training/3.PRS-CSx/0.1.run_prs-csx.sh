SLURM_ARRAY_TASK_ID=1

CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
genotype_files=$CURDIR/data/bfiles/fold$SLURM_ARRAY_TASK_ID
script_dir=$CURDIR/04_PRS_training/3.PRS-CSx
gwas_external_dir=$CURDIR/external_data/GWAS_sources
mcps_gwas_dir=$CURDIR/Training_data/gwas_regenie/CAD_EPA_80_fold_$SLURM_ARRAY_TASK_ID
software_dir=$CURDIR/Software/PRScsx
log_dir=$script_dir/out/fold$SLURM_ARRAY_TASK_ID
LDreference=$CURDIR/external_data/LD_reference

N_THREADS=4
export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS



#cut -d " " -f 17,5,4,10,11 $mcps_gwas_dir/data_mcps_meta-analysis_input.txt > $mcps_gwas_dir/data_mcps_prscsx.txt 
#awk '{ print $17 " " $5 " " $4 " " $10 " " $11}' $mcps_gwas_dir/data_mcps_meta-analysis_input.txt > $mcps_gwas_dir/data_mcps_prscsx.txt 
#sed -i  -e '1s/marker_no_allele/SNP/' -e '1s/effect_allele/A1/' -e '1s/non_effect_allele/A2/' -e '1s/beta/BETA/' -e '1s/se/SE/' $mcps_gwas_dir/data_mcps_prscsx.txt 
 
#first extract column of choice and then change name
awk '{ print $17 " " $5 " " $4 " " $10 " " $11}' \
$mcps_gwas_dir/data_mcps_meta-analysis_input.txt | sed   -e \
'1s/marker_no_allele/SNP/' -e '1s/effect_allele/A1/' -e '1s/non_effect_allele/A2/' \
-e '1s/beta/BETA/' -e '1s/se/SE/'  > $mcps_gwas_dir/data_mcps_prscsx.txt 



module load Anaconda3/2022.05
eval "$(conda shell.bash hook)"

#conda activate 
conda activate prscsx

mkdir $CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID

for chrom in $(seq 1 22);
do 
python $software_dir/PRScsx.py \
--ref_dir=$LDreference \
--bim_prefix=$genotype_files/mcps-subset-chr1 \
--sst_file=$mcps_gwas_dir/data_mcps_prscsx.txt,$gwas_external_dir/BBJCAD_2020_prscsx.txt \
--n_gwas=96270,168228 \
--pop=AMR,EAS \
--chrom=$chrom \
--phi=1e-2 \
--out_dir=$CURDIR/Training_data/PRS/3.PRS-CSx/fold$SLURM_ARRAY_TASK_ID \
--out_name=prscsx \
--meta=TRUE \
--seed=1000 &
done 
wait

