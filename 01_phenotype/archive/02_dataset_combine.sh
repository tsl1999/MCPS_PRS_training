

working_dir=/well/emberson/users/hma817/projects/MCPS_PRS_training
pheno_folder=data

cd $working_dir
echo $PWD
module load R/3.6.2-foss-2019b

Rscript $working_dir/01_phenotype/02_dataset_combine.R $working_dir $pheno_folder