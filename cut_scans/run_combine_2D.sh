#!/bin/bash

#make executable using chmod +x filename.sh

export var=$1
export splitter=$2
export cut=$3

#check if blind argument is given
echo "Running asimov fit"
asimov=true
blind=false
folder=""

path="/work/pahwagne/RDsTools/fit/cut_cards/$cut/${folder}*${var}*${splitter}*_ch*"
dest="/work/pahwagne/RDsTools/fit/cut_cards/$cut/${folder}datacard_${var}_in_${splitter}_regions_combined.txt"

#">" cleans destination to avoid appending with ">>"
> $dest

command_line="combineCards.py "
map_rds=""
map_rdsstar=""

for file in $path; do
 
  echo $file

  bin_number=$(echo "$file" | sed -E 's/.*ch([0-9]+).*/ch\1/')
  echo "==> adding datacard $file for $bin_number"

  #prepare commands
  command_line+="$bin_number=$file "
  map_rds+="--PO map=$bin_number/dsTau:rDs[1,-1,3] "
  map_rdsstar+="--PO map=$bin_number/dsStarTau:rDsStar[1,-1,3] "

done

command_line+=" >> $dest"

echo -e "==> Combining datacards: \n $command_line"

eval $command_line

echo $map_rds
echo $map_rdsstar
cat $dest

#convert datacard into workspace
text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned.root
echo "=======> converted datacard into workspace"

if $asimov; then


  #####################
  # run 2D asimov fit #
  #####################
  echo "-------------------------------- 2D MULTIDIMFIT --------------------------------" 
  combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 -v 2 --algo singles  
  #echo "-------------------------------- 2D MULTIDIMFIT --------------------------------" 
  #combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 -v 2 --algo cross    --cl=0.68
  #combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 -v 0 --algo grid --points 40000 --fastScan -n_2D_scan

  echo "-------------------------------- CONTOUR PLOT --------------------------------" 
  combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 --algo contour2d --points=40 --cl=0.68 -n _68
  combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 --algo contour2d --points=40 --cl=0.95 -n _95
  combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 --algo contour2d --points=40 --cl=0.99 -n _99

  root -l -b -q 'contourPlot.cxx("contours","")'

  #########################################
  # run 1D fit for rDs with rDsStar float #
  #########################################
  
  echo "-------------------------------- 1D SCAN RDs --------------------------------" 
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 400 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 0 -n _1D_scan_rDs_2nd_float_binned --setParameters rDs=1,rDsStar=1
  plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_float_binned --main-label "Asimov"  
  
  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  
  echo "-------------------------------- 1D SCAN RDs* --------------------------------" 
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 400 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 0  -n _1D_scan_rDsStar_2nd_float_binned --setParameters rDs=1,rDsStar=1 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float_binned  --main-label "Asimov"
  
fi

