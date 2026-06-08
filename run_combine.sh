#!/bin/bash

#make executable using chmod +x filename.sh


export datetime=$1
export datacard=$2
export data=$3

#check if blind argument is given
if [ -z "$3" ]; then
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

seed=4234

######################################
# Simple datacards of 1D variables   #
######################################

path="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}${datacard}"

#path="/work/pahwagne/RDsTools/fit/datacards_binned/27_02_2025_17_55_17/blind/datacard_binned_class_constrained_pastNN_q2_coll_ch1.txt"

cat $path

################################### 
# convert datacard into workspace #
################################### 

text2workspace.py $path -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel --PO 'map=ch0/dsTau:rDs[1,-1,3]' --PO 'map=ch0/dsStarTau:rDsStar[1,-1,3]' --PO verbose -o my_workspace.root
echo "=======> converted datacard into workspace"

#combine -M GenerateOnly my_workspace.root --freezeParameters MH -t 5 --setParameters rDs=1,rDsStar=1  --saveToys --toysNoSystematic  


if $asimov; then
  
  echo "asimov"
  #####################
  # run 2D asimov fit #
  #####################
  
  #combine -M MultiDimFit my_workspace.root -t 1 --toysNoSystematics --setParameters rDs=1,rDsStar=1 -v 3 --saveToys
  
  ##########################
  # run 2D likelihood scan #
  ##########################
  
  #combine -M MultiDimFit my_workspace.root -t -1 --setParameters rDs=1,rDsStar=1 -v 3 --algo grid --points 200000 --fastScan -n_2D_scan
  
  #########################################
  # run 1D fit for rDs with rDsStar fixed #
  #########################################
  
  #combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 0 -t -1 -v 3 --setParameters rDs=1     -n _1D_scan_rDs_2nd_fixed
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_fixed.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_fixed --main-label "Asimov" 
  
  #########################################
  # run 1D fit for rDs with rDsStar float #
  #########################################
  
  #combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 2     -n _1D_scan_rDs_2nd_float --setParameters rDs=1,rDsStar=1
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_float --main-label "Asimov" 
  
  ##############################################################
  # run 1D fit for rDsStar with rDs float + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 3 --setParameters rDs=1     --freezeParameters allConstrainedNuisances -n _1D_scan_rDs_2nd_float_freeze_sys
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDs_2nd_float_freeze_sys.MultiDimFit.mH120.root:Stat-Only:2"         --POI rDs -o 1D_scan_rDs_2nd_float_freeze_sys  
 
  ##########################################
  # run toys fit                           # 
  ##########################################
  
  combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t 1 -v 2     -n _1D_scan_rDs_2nd_float_toy -s 546378 --toysNoSystematics --setParameters rDs=1,rDsStar=1
  plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_toy.MultiDimFit.mH120.546378.root --POI rDs -o 1D_scan_rDs_2nd_float_toy --main-label "Asimov" 

 
  #########################################
  # run 1D fit for rDsStar with rDs fixed #
  #########################################
  
  #combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 0 -t -1 -v 3 --setParameters rDsStar=1 -n _1D_scan_rDsStar_2nd_fixed
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_fixed.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_fixed --main-label "Asimov" 
  
  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  
  #combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1 -n _1D_scan_rDsStar_2nd_float --setParameters rDsStar=1,rDs=1
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float  --main-label "Asimov"
  
  ##############################################################
  # run 1D fit for rDsStar with rDs float + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 3 --setParameters rDsStar=1 --freezeParameters allConstrainedNuisances -n _1D_scan_rDsStar_2nd_float_freeze_sys
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDsStar_2nd_float_freeze_sys.MultiDimFit.mH120.root:Stat-Only:2" --POI rDsStar -o 1D_scan_rDsStar_2nd_float_freeze_sys  
  
  ##########################################
  # run toys fit                           # 
  ##########################################

  combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t 1 -v 1 -n _1D_scan_rDsStar_2nd_float_toy  -s 546378 --toysNoSystematics --setParameters rDsStar=1,rDs=1
  plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_toy.MultiDimFit.mH120.546378.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float_toy  --main-label "Asimov"

 
  ##############################
  # Plot 2D likelihood profile #
  # (old, check this)          #
  ##############################
  
  #root -q plot2D_LHScan.cc
  
  #################
  # IMPACT PLOTS  #
  #################
  
  #crashes swith --robustFit 1 as suggested in https://cms-analysis.github.io/HiggsAnalysis-CombinedLimit/tutorial2023/parametric_exercise/?h=impact#two-dimensional-likelihood-scan (section Part6: MultiSignalModel, Impacts) 
  
  #combineTool.py -M Impacts -d my_workspace.root -m 125 --freezeParameters MH -n .impacts --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -t -1 --doInitialFit  --setParameters rDsStar=1,rDs=1
  #combineTool.py -M Impacts -d my_workspace.root -m 125 --freezeParameters MH -n .impacts --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -t -1 --doFits        --setParameters rDsStar=1,rDs=1
  #combineTool.py -M Impacts -d my_workspace.root -m 125 --freezeParameters MH -n .impacts --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -t -1 -o impacts.json --setParameters rDsStar=1,rDs=1
  
  #plotImpacts.py -i impacts.json -o impact_plot_rDs     --POI rDs
  #plotImpacts.py -i impacts.json -o impact_plot_rDsStar --POI rDsStar
  
else

  echo "data"
  #combine -M MultiDimFit my_workspace.root -v 3

  #########################################
  # run 1D fit for rDs with rDsStar float #
  #########################################
  
  combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -v 1     -n _1D_scan_rDs_2nd_float_data_blind
  plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_data_blind.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_float_data_blind --main-label "Blinded Data" 


  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  
  combine -M MultiDimFit my_workspace.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -v 1 -n _1D_scan_rDsStar_2nd_float_data_blind
  plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_data_blind.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float_data_blind  --main-label "Blinded Data"


fi  
