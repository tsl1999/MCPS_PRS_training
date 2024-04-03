CURDIR=/well/emberson/users/hma817/projects/MCPS_PRS_training
MEGA_DIR=$CURDIR/Software/MR-MEGA
EXTERNAL_GWAS=$CURDIR/external_data/GWAS_sources
SCRIPT_DIR=$CURDIR/03_GWAS/03_meta-analysis

module purge
module load Python/3.10.8-GCCcore-12.2.0
#/well/emberson/users/hma817/projects/CAD_GWAS_whole/gwas_regenie/gwas_regenie_CAD_EPA_80/data_mcps_METAL_input.txt

$MEGA_DIR/MR-MEGA \
  -i $SCRIPT_DIR/example_MRMEGA.in \
  --name_pos  position\
  --name_chr chr \
  --name_n N \
  --name_or OR \
  --name_or_95u OR_95U\
  --name_or_95l OR_95L\
  --name_se se \
  --name_eaf effect_allele_freq \
  --name_nea non_effect_allele \
  --name_ea effect_allele \
  --name_marker marker_no_allele\
  --no_std_names \
  -o example_mr-mega