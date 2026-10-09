#!/bin/bash

export datetime=$1
export rDsInit=$2
export rDsStarInit=$3
export nuisance=$4

########################
# Activate singularity #
########################

cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/
/cvmfs/cms.cern.ch/common/cmssw-el7 --bind /pnfs:/pnfs --bind /work:/work --command-to-run "./run_impacts.sh ${datetime} ${rDsInit} ${rDsStarInit} ${nuisance}" 
 
