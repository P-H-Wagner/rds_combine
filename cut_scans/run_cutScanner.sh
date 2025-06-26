#!/bin/bash

for x in $(awk 'BEGIN {for (i=0; i<=300; i++) printf "%.3f ", i/1000}')

do
  #for every cut, we have to copy the run_combine_2D.sh file into a directory
  #since you cannot save into directories directly when running combine?! (wtf?)
  
  mkdir -p "/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/cut_scans/$x"

  #copy 
  cp run_combine_2D.sh ./$x/
  cd $x

  #to save plots
  mkdir -p plots/  

  #submit batch job to do the fit!
  sbatch -p short --time=5 -o out.txt -e err.txt run_combine_2D.sh class q2_coll $x

  cd ..

done
