#!/bin/bash

export var=$1
export splitter=$2
export datetime=$3
export data=$4

#check if blind argument is given
if [ -z "$4" ]; then
  #-z checks if argument 4 is empty
  echo "Running asimov fit"
  asimov=true
  blind=false
  folder=""

else
  echo "Running blinded data fit"
  asimov=false
  blind=True
  folder="blind/"
fi

#make a folder in this directory to save all the plots
toSave="/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/$datetime"
mkdir -p $toSave


path="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}*${var}*${splitter}*_ch*"
dest="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}datacard_${var}_in_${splitter}_regions_combined.txt"

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

#dest="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}datacard_binned_${var}_constrained_pastNN_${splitter}_ch1.txt"
#map_rds=" --PO map=ch1/dsTau:rDs[1,0,5] "
#map_rdsstar=" --PO map=ch1/dsStarTau:rDsStar[1,0,5] "


#convert datacard into workspace
text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned.root
echo "=======> converted datacard into workspace"



for x in $(awk 'BEGIN {for (i=5; i<=15; i++) printf "%.3f ", i/10}')

do

  #set parameter values to $x
  combine -M MultiDimFit my_workspace_binned.root --algo singles --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 0 -n "_asimov_fit_rDs_scan_r_at_$x"     --setParameters rDs=$x,rDsStar=$x
  combine -M MultiDimFit my_workspace_binned.root --algo singles --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 0 -n "_asimov_fit_rDsStar_scan_r_at_$x" --setParameters rDs=$x,rDsStar=$x


done

