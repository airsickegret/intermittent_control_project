#!/bin/bash
#SBATCH --job-name=f_3
#SBATCH --array=80-100
#SBATCH --output=/project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/out_files/rs_CO/LDS_%a_3.out
#SBATCH --output=/project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/error_files/rs_CO/LDS_%a_3.err
#SBATCH --time=1:00:00
#SBATCH --mem-per-cpu=48G
#SBATCH --account=pi-nicho
#SBATCH --partition=caslake
module load python/anaconda-2021.05
source activate /project/nicho/caleb/git/intermittent_control_project/data/ssm_midway_python_environment/
python /project/nicho/caleb/git/intermittent_control_project/code/python_switching_models/LDS_param_search.py 3 CO rs $SLURM_ARRAY_TASK_ID 