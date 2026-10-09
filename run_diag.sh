#!/bin/bash

#make executable using chmod +x filename.sh

export datetime=$1
export rDsInit=$3
export rDsStarInit=$4

cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/${datetime}
cmsenv

combine -M FitDiagnostics my_workspace_binned_${datetime}.root --saveShapes --saveWithUncertainties --saveNormalizations -t -1 --setParameters rDs=${rDsInit},rDsStar=${rDsStarInit} -n _results_asimov_${datetime}  --ignoreCovWarning  --skipBOnlyFit
combine -M FitDiagnostics my_workspace_binned_${datetime}.root --saveShapes --saveWithUncertainties --saveNormalizations -t -1 --setParameters rDs=${rDsInit},rDsStar=${rDsStarInit} -n _results_asimov_B_only_${datetime}  --ignoreCovWarning  --skipSBFit

cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/${datetime}_blind
combine -M FitDiagnostics my_workspace_binned_${datetime}_blind.root --saveShapes --saveWithUncertainties --saveNormalizations --verbose 0 -n _results_data_${datetime}_blind  --ignoreCovWarning --skipBOnlyFit

combine -M FitDiagnostics my_workspace_binned_${datetime}_blind.root --saveShapes --saveWithUncertainties --saveNormalizations --verbose 0 -n _results_data_B_only_${datetime}_blind  --ignoreCovWarning --skipSBFit
