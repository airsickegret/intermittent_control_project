#!/bin/bash
#SBATCH --job-name=22_4_1_0
#SBATCH --output=/project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/out_files/rs_RTP/rSLDS_22_dims_4_states_fold_1_0.out
#SBATCH --output=/project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/error_files/rs_RTP/rSLDS_22_dims_4_states_fold_1_0.err
#SBATCH --time=2:00:00
#SBATCH --mem-per-cpu=48G
#SBATCH --account=pi-nicho
#SBATCH --partition=caslake
module load python/anaconda-2021.05
source activate /project/nicho/caleb/git/intermittent_control_project/data/ssm_midway_python_environment/
python /project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/run_param_search.py 22 1 4 rs RTP 0
sbatch --dependency=afterany:$SLURM_JOB_ID sbatch_24_dims_4_states_fold_1_train-model_1.sh