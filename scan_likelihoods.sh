#!/bin/bash

export datetime=$1
export fittype=$2
export rDsInit=$3
export rDsStarInit=$4

########################
# Activate singularity #
########################

/cvmfs/cms.cern.ch/common/cmssw-el7 --bind /pnfs:/pnfs --bind /work:/work --command-to-run "./run_scan_likelihoods.sh ${datetime} ${fittype} ${rDsInit} ${rDsStarInit}" 
 
