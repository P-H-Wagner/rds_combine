#!/bin/bash

#make executable using chmod +x filename.sh

export datetime=$1
export rDsInit=$3
export rDsStarInit=$4

cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/${datetime}
cmsenv

#KS
echo "---- GOF toy production ----"
combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=KS -t 300 -s 2000 --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_KS_${datetime}
#combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=KS -t 300 -s 2000 --redefineSignalPOIs dsStarYield --setParameters dsStarYield=0.0 -n _gof_KS_${datetime}
echo "---- GOF data ----"
combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=KS               --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_KS_${datetime}
#combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=KS               --redefineSignalPOIs dsStarYield --setParameters dsStarYield=0.0  -n _gof_KS_${datetime}
echo "---- Perform KS test ----"
combineTool.py -M CollectGoodnessOfFit --input higgsCombine_gof_KS_${datetime}.GoodnessOfFit.mH120.root higgsCombine_gof_KS_${datetime}.GoodnessOfFit.mH120.2000.root  -m 120.0 -o gof_KS_${datetime}.json 


#SAT
echo "---- GOF toy production ----"
combine -M GoodnessOfFit ./my_workspace_binned_${datetime}.root --algo=saturated -t 300 -s 2000  --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_saturated_${datetime} --cminDefaultMinimizerStrategy 0  --toysFreq 
#combine -M GoodnessOfFit ./my_workspace_binned_${datetime}.root --algo=saturated -t 300 -s 2000  --redefineSignalPOIs dsStarYield --setParameters dsStarYield=0.0  -n _gof_saturated_${datetime} --cminDefaultMinimizerStrategy 0  --toysFreq 
echo "---- GOF data ----"
combine -M GoodnessOfFit ./my_workspace_binned_${datetime}.root --algo=saturated                 --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_saturated_${datetime}
#combine -M GoodnessOfFit ./my_workspace_binned_${datetime}.root --algo=saturated                 --redefineSignalPOIs dsStarYield --setParameters dsStarYield=0.0  -n _gof_saturated_${datetime}
echo "---- Perform saturated test ----"
combineTool.py -M CollectGoodnessOfFit --input higgsCombine_gof_saturated_${datetime}.GoodnessOfFit.mH120.root higgsCombine_gof_saturated_${datetime}.GoodnessOfFit.mH120.2000.root  -m 120.0 -o gof_saturated_${datetime}.json 


