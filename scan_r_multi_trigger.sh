#!/bin/bash

export var=$1
export splitter=$2
export datetime_mu7=$3
export datetime_mu9=$4
export data=$5

#check if blind argument is given
if [ -z "$5" ]; then
  #-z checks if argument 5 is empty
  echo "######################"
  echo "# Running asimov fit #"
  echo "######################"
  asimov=true
  blind=false
  folder=""

else
  echo "############################"
  echo "# Running blinded data fit #"
  echo "############################"
  asimov=false
  blind=True
  folder="blind/"
fi

#merge datetimes for unique file name for trigger combination
datetime="${datetime_mu7}_and_${datetime_mu9}"

echo "datetime is $datetime"
#make a folder in this directory to save all the plots
toSave="/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/$datetime"
echo "creating directory $toSave"
mkdir -p $toSave


path_mu7="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime_mu7/${folder}*${var}*${splitter}*_ch*"
path_mu9="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime_mu9/${folder}*${var}*${splitter}*_ch*"
                                                                     
dest_mu7="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime_mu7/${folder}datacard_${var}_in_${splitter}_regions_combined.txt"
dest_mu9="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime_mu9/${folder}datacard_${var}_in_${splitter}_regions_combined.txt"

#">" the destination file to avoid appending to it when rerunning combine cards 
> $dest_mu7
> $dest_mu9


#############################################################
# Produce a combined card over all regions for each trigger #
#############################################################

#will hold the parameter mappings for all channels and triggers
map_rds=""
map_rdsstar=""

#######
# mu7 #
#######

echo -e "\n ========> Merging mu7 cards \n"

command_line="combineCards.py "

for file in $path_mu7; do
 
  bin_number=$(echo "$file" | sed -E 's/.*ch([0-9]+).*/ch\1/')
  echo "====> Adding datacard $file for $bin_number"
  #prepare commands
  command_line+="$bin_number=$file "
  #for the workspace
  map_rds+="--PO map=mu7_$bin_number/dsTau:rDs[1,-1,3] "
  map_rdsstar+="--PO map=mu7_$bin_number/dsStarTau:rDsStar[1,-1,3] "

done

#write into mu7 file
command_line+=" >> $dest_mu7"
echo -e "====> Combining datacards: \n $command_line"

eval $command_line

#######
# mu9 #
#######

echo -e "\n ========> Merging mu9 cards \n"

command_line="combineCards.py "

for file in $path_mu9; do
 
  bin_number=$(echo "$file" | sed -E 's/.*ch([0-9]+).*/ch\1/')
  echo "====> Adding datacard $file for $bin_number"
  #prepare commands
  command_line+="$bin_number=$file "
  map_rds+="--PO map=mu9_$bin_number/dsTau:rDs[1,-1,3] "
  map_rdsstar+="--PO map=mu9_$bin_number/dsStarTau:rDsStar[1,-1,3] "

done

#write into mu9 file
command_line+=" >> $dest_mu9"
echo -e "====> Combining datacards: \n $command_line"

eval $command_line



#############################################################
# Produce a combined card over all triggers                 #
#############################################################


echo -e "\n ========> Merging all triggers \n"

#make a folder in the datacard directory to save the combined trigger datacard
echo "====> Combining datetimes for trigger combined datacard to: ${datetime}"
dest_folder="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}"
mkdir -p $dest_folder

#now combine the all the previously created datacards into one, single big datacard
dest="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}datacard_${var}_in_${splitter}_regions_and_trigger_combined.txt"

> $dest

command_line="combineCards.py mu7=${dest_mu7} mu9=${dest_mu9} >> ${dest}"

echo $command_line
eval $command_line


#############################################################
# Add more systematics here                                 #
#############################################################

bin_by_bin_stat="* autoMCStats 0"
#echo -e "\n${bin_by_bin_stat}" >> $dest


#############################################################
# Convert datacard into workspace                           #
#############################################################

echo -e "\n ====> Create workspace \n"

text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned.root
echo "=======> converted datacard into workspace"



for x in $(awk 'BEGIN {for (i=1; i<=30; i++) printf "%.3f ", i/10}')

do

  #set parameter values to $x
  combine -M MultiDimFit my_workspace_binned.root --algo singles --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 0 -n "_asimov_fit_rDs_scan_r_at_$x"     --setParameters rDs=$x,rDsStar=$x
  combine -M MultiDimFit my_workspace_binned.root --algo singles --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 0 -n "_asimov_fit_rDsStar_scan_r_at_$x" --setParameters rDs=$x,rDsStar=$x


done

