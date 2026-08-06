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
  blind=""
  folder=""
 
  #for rds = rdsstar = 1
  lo_rds=0.5
  hi_rds=1.5
  lo_rdsstar=0.75
  hi_rdsstar=1.25

  #for SM values
  lo_rds=-2.0
  hi_rds=2.0
  lo_rdsstar=-2.0
  hi_rdsstar=2.0




else
  echo "Running blinded data fit"
  asimov=false
  blind="_blind"
  folder="blind/"
  #folder=""
  lo_rds=0.0
  hi_rds=3.0
  lo_rdsstar=0.0
  hi_rdsstar=3.0


fi

#lo_rds=-3.0
#hi_rds=3.0
#lo_rdsstar=-3.0
#hi_rdsstar=3.0



#make a folder in this directory to save all the plots
toSave="/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/$datetime"
mkdir -p $toSave

#path="/work/pahwagne/RDsTools/fit/datacards_2D/*${var}*${splitter}*_bin_*"
#dest="/work/pahwagne/RDsTools/fit/datacards_2D/datacard_${var}_in_${splitter}_regions_combined.txt"

#rDsInit=1.0
#rDsStarInit=1.0
rDsInit=0.297
rDsStarInit=0.245 



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
  map_rds+="--PO map=$bin_number/dsTau:rDs[$rDsInit,$lo_rds,$hi_rds] "
  map_rdsstar+="--PO map=$bin_number/dsStarTau:rDsStar[$rDsStarInit,$lo_rdsstar,$hi_rdsstar] "
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
echo -e "\n${bin_by_bin_stat}" >> $dest

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
others="combSys,bsTau"
bbb="prop_binch2_bin4,prob_binch2_bin5,prop_binch3_bin3,prop_binch3_bin4,prop_binch4_bin1,prop_binch6_bin0,prop_binch10_bin0,prob_binch12_bin0,prob_binch13_bin1,prop_binch14_bin0,prop_binch16_bin17"

#autoMCStats are handled by combines Nuisnace group itself!!
all="${rates},${hammer},${yields},${others}"



#convert datacard into workspace
text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned_${datetime}${blind}.root
echo "=======> converted datacard into workspace"

if $asimov; then

  echo "====> Running asimov fits"

  #########################################
  # run 1D fit for rDs with rDs float #
  #########################################
  
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit -n _1D_scan_rDs_float_all_$datetime 
  plot1DScan.py higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ##########################################################
  # run 1D fit for rDs with rDs float and different fixed #
  ##########################################################
  
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters     $hammer     -n _1D_scan_rDs_freeze_hammer_$datetime
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeNuisanceGroups autoMCStats -n _1D_scan_rDs_freeze_mcStats_$datetime
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $bbb -n _1D_scan_rDs_freeze_bbb_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDs_freeze_bbb_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_bbb_$datetime  --main-label "Freeze bbb" \
   
  #########################################################
  # run 1D fit for rDs with rDs float and all   fixed #
  #########################################################
  
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all --freezeNuisanceGroups autoMCStats  -n _1D_scan_rDs_freeze_all_$datetime
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all  -n _1D_scan_rDs_freeze_all_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_all_$datetime  --main-label "Stat. only" \

  ############################
  ## overlay all likelihoods #
  ############################
 
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_overlay_likelihoods_$datetime  --main-label "Stat. only" \
  --others "higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 
  #--others "higgsCombine_1D_scan_rDs_freeze_bbb_${datetime}.MultiDimFit.mH120.root:Freeze bbb:4" "higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 

  ##########################################
  # run toys fit                           # 
  ##########################################
  
  #combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t 1 -v 2     -n _1D_scan_rDs_2nd_float_binned_toy -s 546378 --toysNoSystematics --setParameters rDs=1,rDsStar=1
  #plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned_toy.MultiDimFit.mH120.546378.root --POI rDs -o 1D_scan_rDs_2nd_float_binned_toy --main-label "Asimov" 
 
  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit -n _1D_scan_rDsStar_float_all_$datetime 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ##########################################################
  # run 1D fit for rDsStar with rDs float and hammer fixed #
  ##########################################################
  
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $hammer -n _1D_scan_rDsStar_freeze_hammer_$datetime
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeNuisanceGroups autoMCStats -n _1D_scan_rDsStar_freeze_mcStats_$datetime
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $bbb -n _1D_scan_rDsStar_freeze_bbb_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_bbb_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_bbb_$datetime  --main-label "Freeze bbb" \
   
  #########################################################
  # run 1D fit for rDsStar with rDs float and all   fixed #
  #########################################################
  
  #combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 0 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all --freezeNuisanceGroups autoMCStats  -n _1D_scan_rDsStar_freeze_all_$datetime
  combine -M MultiDimFit my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all  -n _1D_scan_rDsStar_freeze_all_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_all_$datetime  --main-label "Stat. only" \

  ###########################
  # overlay all likelihoods #
  ###########################
 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_overlay_likelihoods_$datetime  --main-label "Stat. only" \
  --others "higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 
  #--others "higgsCombine_1D_scan_rDsStar_freeze_bbb_${datetime}.MultiDimFit.mH120.root:Freeze bbb:4" "higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 

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
  #echo "-------------------------------- CONTOUR PLOT --------------------------------" 
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root -t -1  --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit --algo contour2d --points=40 --cl=0.68 -n _68
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root -t -1  --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit --algo contour2d --points=40 --cl=0.95 -n _95
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root -t -1  --setParameters rDsStar=$rDsStarInit,rDs=$rDsInit --algo contour2d --points=40 --cl=0.99 -n _99
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


  #echo "-------------------------------- IMPACTS --------------------------------" 
  #combineTool.py -M Impacts \
  #  -d my_workspace_binned_${datetime}.root \
  #  -m 125 \
  #  --redefineSignalPOIs rDs \
  #  --setParameters rDsStar=$rDsStarInit \
  #  --floatParameters rDsStar \
  #  -t -1 \
  #  --doInitialFit
 
  #combineTool.py -M Impacts \
  #  -d my_workspace_binned_${datetime}.root \
  #  -m 125 \
  #  --redefineSignalPOIs rDs \
  #  --setParameters rDsStar=$rDsStarInit \
  #  --floatParameters rDsStar \
  #  -t -1 \
  #  --doFits
  #
  #combineTool.py -M Impacts \
  #  -d my_workspace_binned_${datetime}.root \
  #  -m 125 \
  #  --redefineSignalPOIs rDs \
  #  --setParameters rDsStar=$rDsStarInit \
  #  --floatParameters rDsStar \
  #  -t -1 \
  #  -o impacts_rDs_${datetime}.json

  #plotImpacts.py -i impacts_rDs_${datetime}.json -o impacts_rDs_${datetime}



  #echo "-------------------------------- IMPACTS --------------------------------" 

  #combineTool.py -M Impacts \
  #  -d my_workspace_binned_${datetime}.root \
  #  -m 125 \
  #  --redefineSignalPOIs rDsStar \
  #  --setParameters rDs=$rDsInit \
  #  --floatParameters rDs \
  #  -t -1 \
  #  --doInitialFit
 
  #combineTool.py -M Impacts \
  #  -d my_workspace_binned_${datetime}.root \
  #  -m 125 \
  #  --redefineSignalPOIs rDsStar \
  #  --setParameters rDs=$rDsInit \
  #  --floatParameters rDs \
  #  -t -1 \
  #  --doFits
  #
  #combineTool.py -M Impacts \
  #  -d my_workspace_binned_${datetime}.root \
  #  -m 125 \
  #  --redefineSignalPOIs rDsStar \
  #  --setParameters rDs=$rDsInit \
  #  --floatParameters rDs \
  #  -t -1 \
  #  -o impacts_rDsStar_${datetime}.json

  #plotImpacts.py -i impacts_rDsStar_${datetime}.json -o impacts_rDsStar_${datetime}


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


  ###################################################  
  ## Save pre- and posfit shapes, this is a 2D fit! #
  ###################################################  

  combine -M FitDiagnostics my_workspace_binned_${datetime}.root --saveShapes --saveWithUncertainties --saveNormalizations -t -1 --setParameters rDs=1,rDsStar=1 -n _results_asimov_$datetime  --ignoreCovWarning 


else

  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1  -v 1  -n _1D_scan_rDsStar_float_all_data_blind_$datetime${blind} 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_float_all_data_blind_$datetime${blind}  --main-label "Data blind" --main-color=4 \
  ###########################################################
  ## run 1D fit for rDsStar with rDs float and hammer fixed #
  ###########################################################
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1  -v 1  --freezeParameters $hammer -n _1D_scan_rDsStar_freeze_hammer_data_blind_$datetime${blind}
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_hammer_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_hammer_data_blind_$datetime${blind}  --main-label "Freeze Hammer" \
  ##########################################################
  ## run 1D fit for rDsStar with rDs float and bbb fixed #
  ##########################################################
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1  -v 1 --freezeNuisanceGroups autoMCStats -n _1D_scan_rDsStar_freeze_bbb_data_blind_$datetime${blind}
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_bbb_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_bbb_data_blind_$datetime${blind}  --main-label "Freeze bbb" \
  ##########################################################
  ## run 1D fit for rDsStar with rDs float and all   fixed #
  ##########################################################
  combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1  -v 1 --freezeParameters $all --freezeNuisanceGroups autoMCStats -n _1D_scan_rDsStar_freeze_all_data_blind_$datetime${blind}
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_all_data_blind_$datetime${blind}  --main-label "Stat. only" \
  ############################
  ## overlay all likelihoods #
  ############################
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_overlay_likelihoods_data_blind_$datetime${blind}  --main-label "Stat. only" \
  --others "higgsCombine_1D_scan_rDsStar_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2"
  #--others "higgsCombine_1D_scan_rDsStar_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2" "higgsCombine_1D_scan_rDsStar_freeze_bbb_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Freeze bbb:4" 


  
  ##########################################
  ## run 1D fit for rDs with rDs float #
  ##########################################
  combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1  -n _1D_scan_rDs_float_all_data_blind_$datetime${blind}
  plot1DScan.py higgsCombine_1D_scan_rDs_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_float_all_data_blind_$datetime${blind}  --main-label "Data blind" --main-color=4 \
  ############################################################
  ### run 1D fit for rDs with rDs float and hammer fixed #
  ############################################################
  ##combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1  --freezeParameters $hammer -n _1D_scan_rDs_freeze_hammer_data_blind_$datetime${blind}
  ##plot1DScan.py higgsCombine_1D_scan_rDs_freeze_hammer_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_hammer_data_blind_$datetime${blind}  --main-label "Freeze Hammer" \
  ##########################################################
  ## run 1D fit for rDsStar with rDs float and bbb fixed #
  ##########################################################
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1 --freezeNuisanceGroups autoMCStats -n _1D_scan_rDs_freeze_bbb_data_blind_$datetime${blind}
  #plot1DScan.py higgsCombine_1D_scan_rDs_freeze_bbb_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_bbb_data_blind_$datetime${blind}  --main-label "Freeze bbb" \
  ###########################################################
  ### run 1D fit for rDs with rDs float and all   fixed #
  ###########################################################
  combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1 --freezeParameters $all --freezeNuisanceGroups autoMCStats -n _1D_scan_rDs_freeze_all_data_blind_$datetime${blind}
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_all_data_blind_$datetime${blind}  --main-label "Stat. only" \
  ##############################
  #### overlay all likelihoods #
  ##############################
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_overlay_likelihoods_data_blind_$datetime${blind}  --main-label "Stat. only" \
  --others "higgsCombine_1D_scan_rDs_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2" 
  #--others "higgsCombine_1D_scan_rDs_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2" "higgsCombine_1D_scan_rDs_freeze_bbb_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Freeze bbb:4" 


  #################
  # IMPACT PLOTS  #
  #################
  
  #crahse swith --robustFit 1 as suggested in https://cms-analysis.github.io/HiggsAnalysis-CombinedLimit/tutorial2023/parametric_exercise/?h=impact#two-dimensional-likelihood-scan (section Part6: MultiSignalModel, Impacts) 
 
  ##echo "------ IMPACT PLOTS ---------" 
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}${blind}.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind_$datetime${blind} --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit            
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}${blind}.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind_$datetime${blind} --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits                 
  #combineTool.py -M Impacts -d my_workspace_binned_${datetime}${blind}.root -m 125 --freezeParameters MH -n .impacts_binned_data_blind_$datetime${blind} --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -o impacts_binned_data_blind_${datetime}${blind}.json   
  
  #plotImpacts.py -i impacts_binned_data_blind_${datetime}${blind}.json -o impact_plot_rDs_binned_data_blind_$datetime${blind}     --POI rDs     --blind
  #plotImpacts.py -i impacts_binned_data_blind_${datetime}${blind}.json -o impact_plot_rDsStar_binned_data_blind_$datetime${blind} --POI rDsStar --blind


  ###################################################  
  ## Save pre- and posfit shapes, this is a 2D fit! #
  ###################################################  

  combine -M FitDiagnostics my_workspace_binned_${datetime}${blind}.root --saveShapes --saveWithUncertainties --saveNormalizations --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --verbose 0 -n _results_data_${datetime}${blind}  --ignoreCovWarning


fi

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
