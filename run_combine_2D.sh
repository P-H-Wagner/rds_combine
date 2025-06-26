#!/bin/bash

#make executable using chmod +x filename.sh

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

#path="/work/pahwagne/RDsTools/fit/datacards_2D/*${var}*${splitter}*_bin_*"
#dest="/work/pahwagne/RDsTools/fit/datacards_2D/datacard_${var}_in_${splitter}_regions_combined.txt"

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
  #compare with R(D)
  #map_rds+="--PO map=$bin_number/dsTau:rDs[0.3,-1,3] "
  #map_rdsstar+="--PO map=$bin_number/dsStarTau:rDsStar[0.252,-1,3] "

done

command_line+=" >> $dest"

echo -e "==> Combining datacards: \n $command_line"
eval $command_line

echo $map_rds
echo $map_rdsstar

#dest="/work/pahwagne/RDsTools/fit/datacards_binned/$datetime/${folder}datacard_binned_${var}_constrained_pastNN_${splitter}_ch1.txt"
#map_rds=" --PO map=ch1/dsTau:rDs[1,0,5] "
#map_rdsstar=" --PO map=ch1/dsStarTau:rDsStar[1,0,5] "

#testing!!
#dest="/work/pahwagne/RDsTools/fit/datacards_binned/18_06_2025_14_53_07/datacard_binned_q2_lhcb_alt_constrained_pastNN_class_ch1.txt"
echo $dest
cat $dest

#convert datacard into workspace
text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned.root
echo "=======> converted datacard into workspace"

if $asimov; then

  echo "huhu"
  #####################
  # run 2D asimov fit #
  #####################
  
  #combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 -v 1
  
  ##########################
  # run 2D likelihood scan #
  ##########################
  
  #combine -M MultiDimFit my_workspace_binned.root -t -1 --setParameters rDs=1,rDsStar=1 -v 0 --algo grid --points 40000 -n_2D_scan
  
  
  #########################################
  # run 1D fit for rDs with rDsStar fixed #
  #########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 0 -t -1 -v 3 --setParameters rDs=1     -n _1D_scan_rDs_2nd_fixed_binned
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_fixed_binned.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_fixed_binned --main-label "Asimov" 
  
 
  ##############################################################
  # run 1D fit for rDs with rDsStar fixed + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 0 -t -1 -v 1 --setParameters rDs=1     --freezeParameters allConstrainedNuisances -n _1D_scan_rDs_2nd_fixed_freeze_sys_binned
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_fixed_binned.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDs_2nd_fixed_freeze_sys_binned.MultiDimFit.mH120.root:Stat-Only:2"         --POI rDs -o 1D_scan_rDs_2nd_fixed_sys_binned  

  #########################################
  # run 1D fit for rDs with rDsStar float #
  #########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 1 -n _1D_scan_rDs_2nd_float_binned --setParameters rDs=1,rDsStar=1
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_float_binned --main-label "Asimov"  
  
  ##############################################################
  # run 1D fit for rDs with rDsStar float + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 1 --setParameters rDs=1     --freezeParameters allConstrainedNuisances -n _1D_scan_rDs_2nd_float_freeze_sys_binned
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDs_2nd_float_freeze_sys_binned.MultiDimFit.mH120.root:Stat-Only:2"         --POI rDs -o 1D_scan_rDs_2nd_float_sys_binned  
  
  ##########################################
  # run toys fit                           # 
  ##########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t 1 -v 2     -n _1D_scan_rDs_2nd_float_binned_toy -s 546378 --toysNoSystematics --setParameters rDs=1,rDsStar=1
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned_toy.MultiDimFit.mH120.546378.root --POI rDs -o 1D_scan_rDs_2nd_float_binned_toy --main-label "Asimov" 

  #########################################
  # run 1D fit for rDsStar with rDs fixed #
  #########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 0 -t -1 -v 3 --setParameters rDsStar=1 -n _1D_scan_rDsStar_2nd_fixed_binned
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_fixed_binned.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_fixed_binned --main-label "Asimov" 
 
  ##############################################################
  # run 1D fit for rDsStar with rDs fixed + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 0 -t -1 -v 0 --setParameters rDsStar=1 --freezeParameters allConstrainedNuisances -n _1D_scan_rDsStar_2nd_fixed_freeze_sys_binned
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_fixed_binned.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDsStar_2nd_fixed_freeze_sys_binned.MultiDimFit.mH120.root:Stat-Only:2" --POI rDsStar -o 1D_scan_rDsStar_2nd_fixed_sys_binned  
 
  
  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  -n _1D_scan_rDsStar_2nd_float_binned --setParameters rDs=1,rDsStar=1
  plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float_binned  --main-label "Asimov"
  
  ##############################################################
  # run 1D fit for rDsStar with rDs float + freeze Systematics #
  ##############################################################
  
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 0 --setParameters rDs=1,rDsStar=1 --freezeParameters allConstrainedNuisances -n _1D_scan_rDsStar_2nd_float_freeze_sys_binned
  plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDsStar_2nd_float_freeze_sys_binned.MultiDimFit.mH120.root:Stat-Only:2" --POI rDsStar -o 1D_scan_rDsStar_2nd_float_sys_binned  
 
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

  #################
  # IMPACT PLOTS  #
  #################
 
  #combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit          -t -1 --setParameters rDsStar=1,rDs=1 --robustFit 1 
  #combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits                -t -1 --setParameters rDsStar=1,rDs=1
  #combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -o impacts_binned.json  -t -1 --setParameters rDsStar=1,rDs=1 
  
  #plotImpacts.py -i impacts_binned.json -o impact_plot_rDs_binned     --POI rDs     #--blind
  #plotImpacts.py -i impacts_binned.json -o impact_plot_rDsStar_binned --POI rDsStar #--blind

  #########################
  # GOODNESS OF FIT PLOTS #
  #########################
  
  #KS test between data and postfit expectation, calculate KS for all toys and throw a distribution. 
  #combine -M GoodnessOfFit my_workspace_binned.root --algo=KS -t 5 -s 1234  --setParameters rDsStar=1,rDs=1 -n _gof_KS
  #combineTool.py -M CollectGoodnessOfFit --input higgsCombine_gof_KS.GoodnessOfFit.mH120.1234.root -m 125.0 -o _gof_KS.json
  #plotGof.py gof.json --statistic saturated --mass 125.0 -o gof_plot --title-right="my label"

else

  #combine -M MultiDimFit my_workspace_binned.root  --setParameters rDs=0.3,rDsStar=0.3 -v 1
  #########################################
  # run 1D fit for rDs with rDsStar float #
  #########################################
  
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 500 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1  -v 1 -n _1D_scan_rDs_2nd_float_binned_data_blind #--robustFit 1 --cminDefaultMinimizerStrategy 2
  plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned_data_blind.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_float_binned_data_blind --main-label "Data Blind" 

  ##############################################################
  # run 1D fit for rDs with rDs float + freeze Systematics #
  ##############################################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1  -v 1  -n _1D_scan_rDs_2nd_float_freeze_sys_binned_data_blind 
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned_data_blind.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDs_2nd_float_freeze_sys_binned_data_blind.MultiDimFit.mH120.root:Stat-Only:2"         --POI rDs -o 1D_scan_rDs_2nd_float_sys_binned_data_blind 

  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 500 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -v 1  -n _1D_scan_rDsStar_2nd_float_binned_data_blind --robustFit 1 --cminDefaultMinimizerStrategy 1
  plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned_data_blind.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_2nd_float_binned_data_blind  --main-label "Data Blind"
  
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
  #combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit           #--setParameters rDsStar=1,rDs=1 -v 0 
  #combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits                 #--setParameters rDsStar=1,rDs=1 -v 0
  #combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -o impacts_binned_data_blind.json   #--setParameters rDsStar=1,rDs=1 -v 0 
  
  #plotImpacts.py -i impacts_binned_data_blind.json -o impact_plot_rDs_binned_data_blind     --POI rDs     --blind
  #plotImpacts.py -i impacts_binned_data_blind.json -o impact_plot_rDsStar_binned_data_blind --POI rDsStar --blind

  #########################
  # GOODNESS OF FIT PLOTS #
  #########################

  #combine -M GoodnessOfFit -d my_workspace_binned.root --algo=KS -n .gof.data.KS  

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



