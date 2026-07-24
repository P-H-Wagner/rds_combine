#!/bin/bash

#make executable using chmod +x filename.sh

export var=$1
export datetime=$2
export data=$3
export delNuis=$4

#check if blind argument is given
if [ -z "$3" ]; then
  #-z checks if argument 4 is empty
  echo "Running asimov fit"
  asimov=true
  blind=false
  folder=""
  lo=0.5
  hi=1.5

else
  echo "Running blinded data fit"
  asimov=false
  blind=True
  #folder="blind/"
  folder=""
  lo=0.0
  hi=3.0

fi

#make a folder in this directory to save all the plots
toSave="/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/$datetime"
mkdir -p $toSave

#path="/work/pahwagne/RDsTools/fit/datacards_2D/*${var}*${splitter}*_bin_*"
#dest="/work/pahwagne/RDsTools/fit/datacards_2D/datacard_${var}_in_${splitter}_regions_combined.txt"

#rDsInit=0.3
#rDsStarInit=0.252
rDsInit=1.0
rDsStarInit=1.0



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
 
  echo $file

  bin_number=$(echo "$file" | sed -E 's/.*ch([0-9]+).*/ch\1/')

  #temp
  #if [[ $bin_number != "ch7" || $bin_number != "ch13" ]]; then
  if [[ $bin_number == "ch0" ]]; then
  #if [[ $bin_number == "ch5" || $bin_number == "ch6" || $bin_number == "ch7" || $bin_number == "ch8" || $bin_number == "ch9" || $bin_number == "ch10" ]]; then
    continue
  fi

  echo "==> adding datacard $file for $bin_number"

  #prepare commands
  command_line+="$bin_number=$file "
  map_rds+="--PO map=$bin_number/dsTau:rDs[1,$lo,$hi] "
  map_rdsstar+="--PO map=$bin_number/dsStarTau:rDsStar[1,$lo,$hi] "
  #compare with R(D)
  #map_rds+="--PO map=$bin_number/dsTau:rDs[0.3,-1,3] "
  #map_rdsstar+="--PO map=$bin_number/dsStarTau:rDsStar[0.252,-1,3] "

done

command_line+=" >> $dest"

echo -e "==> Combining datacards: \n $command_line"
eval $command_line

echo $map_rds
echo $map_rdsstar

echo $dest
cat $dest


#####################
# OPTION/DEBUG      #
#####################

#delete certain nuisances!
#sed -i '/e10Bgl/d' "$dest"

#validate the combined card
#ValidateDatacards.py $dest

#add systematics
bin_by_bin_stat="* autoMCStats 0"
#echo -e "\n${bin_by_bin_stat}" >> $dest

#echo -e "\nch0 autoMCStats 0" >> $dest
#echo -e "\nch1 autoMCStats 0" >> $dest
#echo -e "\nch2 autoMCStats 0" >> $dest
#echo -e "\nch3 autoMCStats 0" >> $dest
#echo -e "\nch4 autoMCStats  0" >> $dest
#echo -e "\nch5 autoMCStats 0" >> $dest
#echo -e "\nch6 autoMCStats 0" >> $dest
#echo -e "\nch7 autoMCStats 0" >> $dest

#####################
# Group systematics #
#####################

rates="bs,r_hb,r_comb"
yields="bs_fd_yield,bs_dc_yield,bpm_yield,b0_yield,lambda_yield,others_yield,dsYield,dsStarYield"
hammer="e1Bgl,e2Bgl,e3Bgl,e4Bgl,e5Bgl,e6Bgl,e7Bgl,e8Bgl,e9Bgl,e10Bgl,e1Bcl,e2Bcl,e3Bcl,e4Bcl,e5Bcl,e6Bcl"
all="${rates},${hammer},${yields}"

#convert datacard into workspace
text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned_${datetime}.root
echo "=======> converted datacard into workspace"

if $asimov; then

  echo "====> Running asimov fits"

  #########################################
  # run 1D fit for rDs with rDs float #
  #########################################
  
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit -n _1D_scan_rDs_float_all_$datetime 
  plot1DScan.py higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ##########################################################
  # run 1D fit for rDs with rDs float and hammer fixed #
  ##########################################################
  
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $hammer -n _1D_scan_rDs_freeze_hammer_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_hammer_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_hammer_$datetime  --main-label "Freeze Hammer" \
   
  #########################################################
  # run 1D fit for rDs with rDs float and all   fixed #
  #########################################################
  
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all -n _1D_scan_rDs_freeze_all_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_all_$datetime  --main-label "Stat only" \

  ############################
  ## overlay all likelihoods #
  ############################
 
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_overlay_likelihoods_$datetime  --main-label "Stat only" \
  --others "higgsCombine_1D_scan_rDs_freeze_hammer_${datetime}.MultiDimFit.mH120.root:Freeze Hammer:4" "higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 

  ##########################################
  ## run 1D fit for rDs with rDs frozen #
  ##########################################
  #
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=1,rDsStar=1 -n _1D_scan_rDs_2nd_POI_frozen_float_all_$datetime 
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_POI_frozen_float_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_POI_frozen_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ###########################################################
  ## run 1D fit for rDs with rDs frozen and hammer fixed #
  ###########################################################
  #
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=1,rDsStar=1 --freezeParameters $hammer -n _1D_scan_rDs_2nd_POI_frozen_freeze_hammer_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_POI_frozen_freeze_hammer_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_POI_frozen_freeze_hammer_$datetime  --main-label "Freeze Hammer" \
  # 
  ##########################################################
  ## run 1D fit for rDs with rDs frozen and all   fixed #
  ##########################################################
  #
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=1,rDsStar=1 --freezeParameters $all -n _1D_scan_rDs_2nd_POI_frozen_freeze_all_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_POI_frozen_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_POI_frozen_freeze_all_$datetime  --main-label "Stat only" \

  ############################
  ## overlay all likelihoods #
  ############################
 
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_POI_frozen_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_POI_frozen_overlay_likelihoods_$datetime  --main-label "Stat only" \
  #--others "higgsCombine_1D_scan_rDs_2nd_POI_frozen_freeze_hammer_${datetime}.MultiDimFit.mH120.root:Freeze Hammer:4" "higgsCombine_1D_scan_rDs_2nd_POI_frozen_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 



  
  ##########################################
  # run toys fit                           # 
  ##########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t 1 -v 2     -n _1D_scan_rDs_2nd_float_binned_toy -s 546378 --toysNoSystematics --setParameters rDs=1,rDsStar=1
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned_toy.MultiDimFit.mH120.546378.root --POI rDs -o 1D_scan_rDs_2nd_float_binned_toy --main-label "Asimov" 
 
  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit -n _1D_scan_rDsStar_float_all_$datetime 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ##########################################################
  # run 1D fit for rDsStar with rDs float and hammer fixed #
  ##########################################################
  
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $hammer -n _1D_scan_rDsStar_freeze_hammer_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_hammer_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_hammer_$datetime  --main-label "Freeze Hammer" \
   
  #########################################################
  # run 1D fit for rDsStar with rDs float and all   fixed #
  #########################################################
  
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all -n _1D_scan_rDsStar_freeze_all_$datetime
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all -n _1D_scan_rDsStar_freeze_all_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_all_$datetime  --main-label "Stat only" \

  ###########################
  # overlay all likelihoods #
  ###########################
 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_overlay_likelihoods_$datetime  --main-label "Stat only" \
  --others "higgsCombine_1D_scan_rDsStar_freeze_hammer_${datetime}.MultiDimFit.mH120.root:Freeze Hammer:4" "higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 

  ##########################################
  ## run 1D fit for rDsStar with rDs frozen #
  ##########################################
  #
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=1,rDsStar=1 -n _1D_scan_rDsStar_2nd_POI_frozen_float_all_$datetime 
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_POI_frozen_float_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_POI_frozen_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ###########################################################
  ## run 1D fit for rDsStar with rDs frozen and hammer fixed #
  ###########################################################
  #
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=1,rDsStar=1 --freezeParameters $hammer -n _1D_scan_rDsStar_2nd_POI_frozen_freeze_hammer_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_POI_frozen_freeze_hammer_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_POI_frozen_freeze_hammer_$datetime  --main-label "Freeze Hammer" \
  # 
  ##########################################################
  ## run 1D fit for rDsStar with rDs frozen and all   fixed #
  ##########################################################
  #
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=1,rDsStar=1 --freezeParameters $all -n _1D_scan_rDsStar_2nd_POI_frozen_freeze_all_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_POI_frozen_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_POI_frozen_freeze_all_$datetime  --main-label "Stat only" \

  ############################
  ## overlay all likelihoods #
  ############################
 
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_POI_frozen_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_POI_frozen_overlay_likelihoods_$datetime  --main-label "Stat only" \
  #--others "higgsCombine_1D_scan_rDsStar_2nd_POI_frozen_freeze_hammer_${datetime}.MultiDimFit.mH120.root:Freeze Hammer:4" "higgsCombine_1D_scan_rDsStar_2nd_POI_frozen_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 



  ##########################################
  # run toys fit                           # 
  ##########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t 1 -v 1     -n _1D_scan_rDsStar_2nd_float_binned_toy -s 546378 --toysNoSystematics --setParameters rDs=1,rDsStar=1
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned_toy.MultiDimFit.mH120.546378.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float_binned_toy --main-label "Asimov" 
 
  ##############################
  # Plot 2D likelihood profile #
  # (old, check this)          #
  ##############################
  
  #root -q plot2D_LHScan.cc
  echo "-------------------------------- CONTOUR PLOT --------------------------------" 
  #combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=0.252,rDs=0.3 --algo contour2d --points=40 --cl=0.68 -n _68
  #combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=0.252,rDs=0.3 --algo contour2d --points=40 --cl=0.95 -n _95
  #combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=0.252,rDs=0.3 --algo contour2d --points=40 --cl=0.99 -n _99
  #combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=1.0,rDs=1.0 --algo contour2d --points=40 --cl=0.68 -n _68
  #combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=1.0,rDs=1.0 --algo contour2d --points=40 --cl=0.95 -n _95
  #combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=1.0,rDs=1.0 --algo contour2d --points=40 --cl=0.99 -n _99

  #root -l -b -q 'contourPlot.cxx("contours","")'

  ##################
  ## IMPACT PLOTS  #
  ##################
 
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH -n .impacts_binned_$datetime --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit          -t -1 --setParameters rDsStar=1,rDs=1 --robustFit 1 
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH -n .impacts_binned_$datetime --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits                -t -1 --setParameters rDsStar=1,rDs=1
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH -n .impacts_binned_$datetime --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -o impacts_binned_${datetime}.json  -t -1 --setParameters rDsStar=1,rDs=1 
 
  #plotImpacts.py -i impacts_binned_${datetime}.json -o impact_plot_rDs_binned_$datetime     --POI rDs     #--blind
  #plotImpacts.py -i impacts_binned_${datetime}.json -o impact_plot_rDsStar_binned_$datetime --POI rDsStar #--blind


  echo "-------------------------------- IMPACTS --------------------------------" 
  combineTool.py -M Impacts \
    -d my_workspace_binned_${datetime}.root \
    -m 125 \
    --redefineSignalPOIs rDs \
    --setParameters rDsStar=$rDsStarInit \
    --floatParameters rDsStar \
    -t -1 \
    --doInitialFit
 
  combineTool.py -M Impacts \
    -d my_workspace_binned_${datetime}.root \
    -m 125 \
    --redefineSignalPOIs rDs \
    --setParameters rDsStar=$rDsStarInit \
    --floatParameters rDsStar \
    -t -1 \
    --doFits
  
  combineTool.py -M Impacts \
    -d my_workspace_binned_${datetime}.root \
    -m 125 \
    --redefineSignalPOIs rDs \
    --setParameters rDsStar=$rDsStarInit \
    --floatParameters rDsStar \
    -t -1 \
    -o impacts_rDs_${datetime}.json

  plotImpacts.py -i impacts_rDs_${datetime}.json -o impacts_rDs_${datetime}



  echo "-------------------------------- IMPACTS --------------------------------" 

  combineTool.py -M Impacts \
    -d my_workspace_binned_${datetime}.root \
    -m 125 \
    --redefineSignalPOIs rDsStar \
    --setParameters rDs=$rDsInit \
    --floatParameters rDs \
    -t -1 \
    --doInitialFit
 
  combineTool.py -M Impacts \
    -d my_workspace_binned_${datetime}.root \
    -m 125 \
    --redefineSignalPOIs rDsStar \
    --setParameters rDs=$rDsInit \
    --floatParameters rDs \
    -t -1 \
    --doFits
  
  combineTool.py -M Impacts \
    -d my_workspace_binned_${datetime}.root \
    -m 125 \
    --redefineSignalPOIs rDsStar \
    --setParameters rDs=$rDsInit \
    --floatParameters rDs \
    -t -1 \
    -o impacts_rDsStar_${datetime}.json

  plotImpacts.py -i impacts_rDsStar_${datetime}.json -o impacts_rDsStar_${datetime}


  ###########################
  ### GOODNESS OF FIT PLOTS #
  ###########################
  ##

  #KS test between data and postfit expectation, calculate KS for all toys and throw a distribution. 
  echo "---- GOF toy production ----"
  combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=KS -t 80 -s 1968 --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_KS_${datetime}
  echo "---- GOF data ----"
  combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=KS               --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_KS_${datetime}
  echo "---- Perform KS test ----"
  combineTool.py -M CollectGoodnessOfFit --input higgsCombine_gof_KS_${datetime}.GoodnessOfFit.mH120.root higgsCombine_gof_KS_${datetime}.GoodnessOfFit.mH120.1968.root  -m 120.0 -o gof_KS_${datetime}.json 
 
  #plotGof.py gof_KS_${datetime}.json --statistic KS --mass 120.0 -o gof_plot_KS_${datetime} --title-right="GoF KS" --range 0 0.01

  echo "---- GOF toy production ----"
  combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=saturated -t 80 -s 1968  --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_saturated_${datetime}
  echo "---- GOF data ----"
  combine -M GoodnessOfFit my_workspace_binned_${datetime}.root --algo=saturated               --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit -n _gof_saturated_${datetime}
  echo "---- Perform saturated test ----"
  combineTool.py -M CollectGoodnessOfFit --input higgsCombine_gof_saturated_${datetime}.GoodnessOfFit.mH120.root higgsCombine_gof_saturated_${datetime}.GoodnessOfFit.mH120.1968.root  -m 120.0 -o gof_saturated_${datetime}.json 
 
  #plotGof.py gof_saturated_${datetime}.json --statistic saturated --mass 120.0 -o gof_plot_sat_${datetime} --title-right="GoF Saturated" --range 0 0.01


  ##################################################  
  # Save pre- and posfit shapes, this is a 2D fit! #
  ##################################################  

  combine -M FitDiagnostics my_workspace_binned_${datetime}.root --saveShapes --saveWithUncertainties --saveNormalizations -t -1 --setParameters rDs=1,rDsStar=1 -n _results_asimov_$datetime  --ignoreCovWarning 


else

  #combine -M MultiDimFit my_workspace_binned.root  --setParameters rDs=0.3,rDsStar=0.3 -v 1
  #########################################
  # run 1D fit for rDs with rDsStar float #
  #########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 500 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1  -v 1 -n _1D_scan_rDs_2nd_float_binned_data_blind --setParameters rDs=1,rDsStar=1
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned_data_blind.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_float_binned_data_blind --main-label "Data Blind" 

  ##############################################################
  # run 1D fit for rDs with rDs float + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1  -v 1  -n _1D_scan_rDs_2nd_float_freeze_sys_binned_data_blind 
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned_data_blind.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDs_2nd_float_freeze_sys_binned_data_blind.MultiDimFit.mH120.root:Stat-Only:2"         --POI rDs -o 1D_scan_rDs_2nd_float_sys_binned_data_blind 

  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
 
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -v 0  -n _1D_scan_rDsStar_2nd_float_binned_data_blind --robustFit 1 --setParameters rDs=1,rDsStar=1 --saveFitResult 
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned_data_blind.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float_binned_data_blind  --main-label "Data Blind"
 
  #combine -M FitDiagnostics my_workspace_binned.root \
  #  --saveShapes \
  #  --saveWithUncertainties \
  #  --saveNormalizations \
  #  --robustFit 1 \
  #  --setParameters rDs=1,rDsStar=1 \
  #  -n _1D_scan_rDsStar_2nd_float_binned_data_blind_shapes_and_norm
 
  ##############################################################
  # run 1D fit for rDsStar with rDs float + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -v 0  -n _1D_scan_rDsStar_2nd_float_freeze_sys_binned_data_blind
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned_data_blind.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDsStar_2nd_float_freeze_sys_binned_data_blind.MultiDimFit.mH120.root:Stat-Only:2" --POI rDsStar -o 1D_scan_rDsStar_2nd_float_sys_binned_data_blind  

  #################
  # IMPACT PLOTS  #
  #################
  
  #crahse swith --robustFit 1 as suggested in https://cms-analysis.github.io/HiggsAnalysis-CombinedLimit/tutorial2023/parametric_exercise/?h=impact#two-dimensional-likelihood-scan (section Part6: MultiSignalModel, Impacts) 
 
  #echo "------ IMPACT PLOTS ---------" 
  combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind_$datetime --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit           #--setParameters rDsStar=1,rDs=1 -v 0 
  combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind_$datetime --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits                 #--setParameters rDsStar=1,rDs=1 -v 0
  combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind_$datetime --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -o impacts_binned_data_blind_${datetime}.json   #--setParameters rDsStar=1,rDs=1 -v 0 
  
  plotImpacts.py -i impacts_binned_data_blind_${datetime}.json -o impact_plot_rDs_binned_data_blind_$datetime     --POI rDs     --blind
  plotImpacts.py -i impacts_binned_data_blind_${datetime}.json -o impact_plot_rDsStar_binned_data_blind_$datetime --POI rDsStar --blind


  #####################
  # IMPACT FREEZE RDS #
  #####################

  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH,rDs -n .impacts_binned_data_blind_freeze_rDs_$datetime --cminDefaultMinimizerStrategy 0 -P rDsStar --doInitialFit                                             --setParameters rDs=1 -v 0 
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH,rDs -n .impacts_binned_data_blind_freeze_rDs_$datetime --cminDefaultMinimizerStrategy 0 -P rDsStar --doFits                                                   --setParameters rDs=1 -v 0
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH,rDs -n .impacts_binned_data_blind_freeze_rDs_$datetime --cminDefaultMinimizerStrategy 0 -P rDsStar -o impacts_binned_data_blind_freeze_rDs_${datetime}.json   --setParameters rDs=1 -v 0 
  
  #plotImpacts.py -i impacts_binned_data_blind_freeze_rDs_${datetime}.json -o impact_plot_rDsStar_binned_data_blind_freeze_rDs_$datetime --POI rDsStar --blind

  #########################
  # IMPACT FREEZE RDSStar #
  #########################


  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH,rDsStar -n .impacts_binned_data_blind_freeze_rDsStar_$datetime --cminDefaultMinimizerStrategy 0 -P rDs --doInitialFit                                                 --setParameters rDsStar=1 -v 0 
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH,rDsStar -n .impacts_binned_data_blind_freeze_rDsStar_$datetime --cminDefaultMinimizerStrategy 0 -P rDs --doFits                                                       --setParameters rDsStar=1 -v 0
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}.root -m 125 --freezeParameters MH,rDsStar -n .impacts_binned_data_blind_freeze_rDsStar_$datetime --cminDefaultMinimizerStrategy 0 -P rDs -o impacts_binned_data_blind_freeze_rDsStar_${datetime}.json   --setParameters rDsStar=1 -v 0 
  
  #plotImpacts.py -i impacts_binned_data_blind_freeze_rDsStar_${datetime}.json -o impact_plot_rDsStar_binned_data_blind_freeze_rDsStar_$datetime --POI rDs --blind


  ################
  # CORRELATION  #
  ################

  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -v 0 --setParameters rDs=1,rDsStar=1  --cminDefaultMinimizerStrategy 0 --robustHesse 1 --robustHesseSave 1  --saveFitResult -n _1D_scan_rDsStar_with_all_float_hesse_data
  #########################
  # GOODNESS OF FIT PLOTS #
  #########################

  #combine -M GoodnessOfFit -d my_workspace_binned.root --algo=KS -n .gof.data.KS  

  ##################################################  
  # Save pre- and posfit shapes, this is a 2D fit! #
  ##################################################  

  combine -M FitDiagnostics my_workspace_binned_$datetime.root --saveShapes --saveWithUncertainties --saveNormalizations --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --verbose 0 -n _results_data_$datetime  --ignoreCovWarning


fi

#################
# IMPACT PLOTS  #
#################

#crahse swith --robustFit 1 as suggested in https://cms-analysis.github.io/HiggsAnalysis-CombinedLimit/tutorial2023/parametric_exercise/?h=impact#two-dimensional-likelihood-scan (section Part6: MultiSignalModel, Impacts) 

#combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit           #--setParameters rDsStar=1,rDs=1 -v 0 
#combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits                 #--setParameters rDsStar=1,rDs=1 -v 0
#combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -o impacts_binned_data_blind.json   #--setParameters rDsStar=1,rDs=1 -v 0 

#plotImpacts.py -i impacts_binned_data_blind.json -o impact_plot_rDs_binned_data_blind     --POI rDs     --blind
#plotImpacts.py -i impacts_binned_data_blind.json -o impact_plot_rDsStar_binned_data_blind --POI rDsStar --blind


#####################
# Goodness of fits  #
#####################

# run the data
#combine -M GoodnessOfFit my_workspace_binned.root --algo=KS        -n .gof_data_ks
#combine -M GoodnessOfFit my_workspace_binned.root --algo=saturated -n .gof_data_ks

# run on mc toy samples -t 20 specifies the number of toy sets
#combine -M GoodnessOfFit my_workspace_binned.root --algo=KS        -t 20 -s 1968  -n .gof_toys_ks
#combine -M GoodnessOfFit my_workspace_binned.root --algo=saturated -t 20 -s 1968 



if [ -z "$datetime" ]; then
    echo "ERROR: datetime is empty"
    exit 1
fi


mkdir -p ./${datetime}
echo "copying everything into folder ..." 
cp *${datetime}*  ./${datetime}
rm *${datetime}*
echo "DONE" 
