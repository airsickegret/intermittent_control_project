#!/bin/bash
#SBATCH --job-name=42_6_4_0
#SBATCH --output=/project/nicho/projects/caleb/git/intermittent_control_project/code/python_switching_models/out_files/rj_RTP/rSLDS_42_dims_6_states_fold_4_0.out
#SBATCH --output=/project/nicho/projects/caleb/git/intermittent_control_project/code/python_switching_models/error_files/rj_RTP/rSLDS_42_dims_6_states_fold_4_0.err
#SBATCH --time=3:00:00
#SBATCH --mem-per-cpu=48G
#SBATCH --account=pi-nicho
#SBATCH --partition=caslake
module load python/anaconda-2021.05
source activate /project/nicho/projects/caleb/git/intermittent_control_project/data/ssm_midway_python_environment/
python /project/nicho/projects/caleb/git/intermittent_control_project/code/python_switching_models/run_param_search.py 42 4 6 rj RTP 0
sbatch --dependency=afterany:$SLURM_JOB_ID sbatch_46_dims_6_states_fold_4_train-model_1.sh