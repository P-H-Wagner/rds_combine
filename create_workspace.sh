#!/bin/bash

#make executable using chmod +x filename.sh

export var=$1
export datetime=$2
export data=$3
export rDsInit=$4
export rDsStarInit=$5

cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine
cmsenv

#check if blind argument is given
if [[ $3 == "asimov" ]]; then
  #-z checks if argument 4 is empty
  echo "Running ASIMOV fit"
  asimov=true
  blind=""
  folder=""
 
  #for rds = rdsstar = 1
  lo_rds=0.5
  hi_rds=1.5
  lo_rdsstar=0.75
  hi_rdsstar=1.25

  #for SM values
  lo_rds=-3.0
  hi_rds=3.0
  lo_rdsstar=-3.0
  hi_rdsstar=3.0


else
  echo "Running blinded DATA fit"
  asimov=false
  blind="_blind"
  folder="blind/"
  #folder=""
  lo_rds=-3.0
  hi_rds=3.0
  lo_rdsstar=-3.0
  hi_rdsstar=3.0


fi


#make a folder in this directory to save all the plots
toSave="/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/$datetime"
mkdir -p $toSave

#set SM values
#rDsInit=0.297
#rDsStarInit=0.245 


if [[ $var == "combo" ]]; then
  path="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}*ch*" 
else 
  path="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}*${var}*_ch*"
fi

dest="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}datacard_${var}_in_regions_combined.txt"

#">" cleans destination to avoid appending with ">>"
> $dest

command_line="combineCards.py "
map_rds=""
map_rdsstar=""

for file in $path; do
 
  #echo $file

  bin_number=$(echo "$file" | sed -E 's/.*ch([0-9]+).*/ch\1/')

  #temp
  if [[ $bin_number == "ch0" ]]; then
  #if [[ $bin_number == "ch0" || $bin_number == "ch3" ]]; then
  #if [[ $bin_number == "ch0" || $bin_number == "ch2" || $bin_number == "ch3" || $bin_number == "ch6" ]]; then
  #if [[ $bin_number == "ch0" || $bin_number == "ch13" ]]; then
  #if [[ $bin_number == "ch2" || $bin_number == "ch4" || $bin_number == "ch0" || $bin_number == "ch1" || $bin_number == "ch8" || $bin_number == "ch12" || $bin_number == "ch10" || $bin_number == "ch15" ]]; then
  #if [[ $bin_number == "ch5" || $bin_number == "ch6" || $bin_number == "ch7" || $bin_number == "ch8" || $bin_number == "ch9" || $bin_number == "ch10" ]]; then
    continue
  fi

  echo "==> adding datacard $file for $bin_number"

  #prepare commands
  command_line+="$bin_number=$file "
  map_rds+="--PO map=$bin_number/dsTau:rDs[$rDsInit,$lo_rds,$hi_rds] "
  map_rdsstar+="--PO map=$bin_number/dsStarTau:rDsStar[$rDsStarInit,$lo_rdsstar,$hi_rdsstar] "
  #compare with R(D)
  #map_rds+="--PO map=$bin_number/dsTau:rDs[0.3,-1,3] "
  #map_rdsstar+="--PO map=$bin_number/dsStarTau:rDsStar[0.252,-1,3] "

done

command_line+=" >> $dest"

#echo -e "==> Combining datacards: \n $command_line"
eval $command_line

#echo $map_rds
#echo $map_rdsstar
#echo $dest
#cat  $dest


#####################
# OPTION/DEBUG      #
#####################

#delete certain nuisances!
#sed -i '/e10Bgl/d' "$dest"

#add systematics
bin_by_bin_stat="* autoMCStats 0"
echo -e "\n${bin_by_bin_stat}" >> $dest

#echo -e "\nch0 autoMCStats 0" >> $dest
#echo -e "\nch1 autoMCStats 0" >> $dest
#echo -e "\nch2 autoMCStats 0" >> $dest
#echo -e "\nch3 autoMCStats 0" >> $dest
#echo -e "\nch4 autoMCStats  0" >> $dest
#echo -e "\nch5 autoMCStats 0" >> $dest
#echo -e "\nch6 autoMCStats 0" >> $dest
#echo -e "\nch7 autoMCStats 0" >> $dest


#convert datacard into workspace
text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned_${datetime}${blind}.root
echo "=======> Converted datacard into workspace"

##########
# SAVING #
##########

if [ -z "$datetime" ]; then
    echo "ERROR: datetime is empty"
    exit 1
fi

mkdir -p ./${datetime}${blind}
echo "copying everything into folder ..." 
cp *${datetime}${blind}*  ./${datetime}${blind}
rm *${datetime}${blind}*
echo "DONE" 

exit
