#!/bin/bash

#make executable using chmod +x filename.sh

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

#make a folder in this directory to save all the plots
toSave="/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/$datetime"
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

#echo -e "\nmu7_ch0 autoMCStats 0" >> $dest
#echo -e "\nmu7_ch1 autoMCStats 0" >> $dest
#echo -e "\nmu7_ch2 autoMCStats 0" >> $dest
#echo -e "\nmu7_ch3 autoMCStats 0" >> $dest
#echo -e "\nmu7_ch4 autoMCStats 0" >> $dest
#echo -e "\nmu7_ch5 autoMCStats 0" >> $dest
#echo -e "\nmu7_ch6 autoMCStats 0" >> $dest
#echo -e "\nmu7_ch7 autoMCStats 0" >> $dest
#
#echo -e "\nmu9_ch0 autoMCStats 0" >> $dest
#echo -e "\nmu9_ch1 autoMCStats 0" >> $dest
#echo -e "\nmu9_ch2 autoMCStats 0" >> $dest
#echo -e "\nmu9_ch3 autoMCStats 0" >> $dest
#echo -e "\nmu9_ch4 autoMCStats 0" >> $dest
#echo -e "\nmu9_ch5 autoMCStats 0" >> $dest
#echo -e "\nmu9_ch6 autoMCStats 0" >> $dest
#echo -e "\nmu9_ch7 autoMCStats 0" >> $dest


#############################################################
# Convert datacard into workspace                           #
#############################################################

echo -e "\n ====> Create workspace \n"
echo "text2workspace.py ${dest} -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel ${map_rds} ${map_rdsstar} --PO verbose -o my_workspace_binned.root"
text2workspace.py $dest -P HiggsAnalysis.CombinedLimit.PhysicsModel:multiSignalModel $map_rds $map_rdsstar --PO verbose -o my_workspace_binned.root


# save this to latex
combine -M FitDiagnostics ${dest} --saveNormalizations
#python mlfitNormsToText.py fitDiagnosticsTest.root > norms.txt

echo -e "\n ======== PREPARATION DONE, START FITTING ========\n"


#
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
  
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 1 -n _1D_scan_rDs_2nd_float_binned --setParameters rDs=1,rDsStar=1
  plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_2nd_float_binned --main-label "Asimov"  
  
  ##################################################################
  # run 1D fit for rDs with rDsStar float + freeze all Systematics #
  ##################################################################
  
  combine -M MultiDimFit my_workspace_binned.root --algo grid --points 200 --saveInactivePOI 1 -P rDs     --floatOtherPOIs 1 -t -1 -v 1 --setParameters rDs=1     --freezeParameters allConstrainedNuisances -n _1D_scan_rDs_2nd_float_freeze_sys_binned
  plot1DScan.py higgsCombine_1D_scan_rDs_2nd_float_binned.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDs_2nd_float_freeze_sys_binned.MultiDimFit.mH120.root:Stat-Only:2" --main-label "Asimov" --POI rDs -o 1D_scan_rDs_2nd_float_sys_binned  

 
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
  plot1DScan.py higgsCombine_1D_scan_rDsStar_2nd_float_binned.MultiDimFit.mH120.root --others "higgsCombine_1D_scan_rDsStar_2nd_float_freeze_sys_binned.MultiDimFit.mH120.root:Stat-Only:2" --main-label "Asimov" --POI rDsStar -o 1D_scan_rDsStar_2nd_float_sys_binned  


 #
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
  combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=1.0,rDs=1.0 --algo contour2d --points=40 --cl=0.68 -n _68
  combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=1.0,rDs=1.0 --algo contour2d --points=40 --cl=0.95 -n _95
  combine -M MultiDimFit my_workspace_binned.root -t -1  --setParameters rDsStar=1.0,rDs=1.0 --algo contour2d --points=40 --cl=0.99 -n _99

  root -l -b -q 'contourPlot.cxx("contours","")'

  ##################
  ## IMPACT PLOTS  #
  ##################
 
  combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit          -t -1 --setParameters rDsStar=1,rDs=1 --robustFit 1 
  combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doFits                -t -1 --setParameters rDsStar=1,rDs=1
  combineTool.py -M Impacts -d my_workspace_binned.root -m 125 --freezeParameters MH -n .impacts_binned --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar -o impacts_binned.json  -t -1 --setParameters rDsStar=1,rDs=1 
  #
  plotImpacts.py -i impacts_binned.json -o impact_plot_rDs_binned     --POI rDs     #--blind
  plotImpacts.py -i impacts_binned.json -o impact_plot_rDsStar_binned --POI rDsStar #--blind

  ##########################
  ## GOODNESS OF FIT PLOTS #
  ##########################
  #
  #KS test between data and postfit expectation, calculate KS for all toys and throw a distribution. 
  #echo "---- GOF toy production ----"
  #combine -M GoodnessOfFit my_workspace_binned.root --algo=KS -t 200 -s 1234  --setParameters rDsStar=1,rDs=1 -n _gof_KS
  #echo "---- GOF data ----"
  #combine -M GoodnessOfFit my_workspace_binned.root --algo=KS               --setParameters rDsStar=1,rDs=1 -n _gof_KS
  #echo "---- Perform KS test ----"
  #combineTool.py -M CollectGoodnessOfFit --input higgsCombine_gof_KS.GoodnessOfFit.mH120.root higgsCombine_gof_KS.GoodnessOfFit.mH120.1234.root  -m 120.0 -o gof_KS.json 
 
  #plotGof.py gof_KS.json --statistic KS --mass 120.0 -o gof_plot --title-right="GoF" --range 0 0.01

  #echo "---- GOF toy production ----"
  #combine -M GoodnessOfFit my_workspace_binned.root --algo=saturated -t 200 -s 1234  --setParameters rDsStar=1,rDs=1 -n _gof_saturated
  #echo "---- GOF data ----"
  #combine -M GoodnessOfFit my_workspace_binned.root --algo=saturated               --setParameters rDsStar=1,rDs=1 -n _gof_saturated
  #echo "---- Perform saturated test ----"
  #combineTool.py -M CollectGoodnessOfFit --input higgsCombine_gof_saturated.GoodnessOfFit.mH120.root higgsCombine_gof_saturated.GoodnessOfFit.mH120.1234.root  -m 120.0 -o gof_saturated.json 
 
  #plotGof.py gof_saturated.json --statistic saturated --mass 120.0 -o gof_plot --title-right="GoF" --range 0 0.01

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



