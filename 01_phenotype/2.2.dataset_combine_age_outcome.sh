

working_dir=/well/emberson/users/hma817/projects/MCPS_PRS_training
pheno_folder=data

cd $working_dir
echo $PWD
module load R/4.2.1-foss-2022a



#80 EPA
Rscript $working_dir/01_phenotype/2.1.dataset_combine_age_outcome.R $working_dir $pheno_folder 80 EPA001 BASE_CHD CAD_EPA

#80 EPO
Rscript $working_dir/01_phenotype/2.1.dataset_combine_age_outcome.R $working_dir $pheno_folder 80 EPO001 BASE_CHD CAD_EPO
