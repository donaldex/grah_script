#!/bin/bash
#SBATCH -o out_NCL_QSS_3Dcheck_velo_color
#SBATCH -e error_NCL_QSS_3Dcheck_velo_color
#SBATCH --mem=8G
#SBATCH --time=12:00:00 
ncl NCL_QSS_3Dcheck_velo_color
