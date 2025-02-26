#!/bin/bash
#SBATCH --job-name=78_38_4_0
#SBATCH --output=/project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/out_files/bx18_CO/rSLDS_78_dims_38_states_fold_4_0.out
#SBATCH --output=/project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/error_files/bx18_CO/rSLDS_78_dims_38_states_fold_4_0.err
#SBATCH --time=27:00:00
#SBATCH --mem-per-cpu=48G
#SBATCH --account=pi-nicho
#SBATCH --partition=caslake
module load python/anaconda-2021.05
source activate /project/nicho/caleb/git/intermittent_control_project/data/ssm_midway_python_environment/
python /project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/run_param_search.py 78 4 38 bx18 CO 0
sbatch --dependency=afterany:$SLURM_JOB_ID sbatch_80_dims_38_states_fold_4_train-model_1.sh