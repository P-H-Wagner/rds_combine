#!/bin/bash

#make executable using chmod +x filename.sh

export datetime=$1
export rDsInit=$2
export rDsStarInit=$3
export nuisance=$4

cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/${datetime}
cmsenv

combineTool.py -M Impacts -d ./my_workspace_binned_${datetime}.root -m 125 --cminDefaultMinimizerStrategy 0 --redefineSignalPOIs rDs     --setParameters rDsStar=$rDsStarInit --floatParameters rDsStar -t -1 --doFits --named $nuisance -n .impacts_rDs_$datetime 
combineTool.py -M Impacts -d ./my_workspace_binned_${datetime}.root -m 125 --cminDefaultMinimizerStrategy 0 --redefineSignalPOIs rDsStar --setParameters rDs=$rDsInit         --floatParameters rDs     -t -1 --doFits --named $nuisance -n .impacts_rDsStar_$datetime

cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/${datetime}_blind/
combineTool.py -M Impacts -d ./my_workspace_binned_${datetime}_blind.root -m 125 --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits --named $nuisance -n .impacts_data_$datetime
