#!/bin/bash

export datetime=$1
export fittype=$2
export rDsInit=$3
export rDsStarInit=$4


cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/${datetime}
cmsenv


#####################
# Group systematics #
#####################


#rates="bs,r_hb,r_comb"
rates="r_b,r_comb,alpha,r_hb"
yields="bs_fd_yield,bs_dc_yield,bpm_yield,b0_yield,lambda_yield,others_yield,dsYield,dsStarYield"
hammer="e1Bgl,e2Bgl,e3Bgl,e4Bgl,e5Bgl,e6Bgl,e7Bgl,e8Bgl,e9Bgl,e10Bgl,e1Bcl,e2Bcl,e3Bcl,e4Bcl,e5Bcl,e6Bcl"
bs_prop="bsTau,bsKin"
datamc="triggerSF,pu"
others="combSys_ch2,combSys_ch3"
bbb="prop_binch2_bin4,prob_binch2_bin5,prop_binch3_bin3,prop_binch3_bin4,prop_binch4_bin1,prop_binch6_bin0,prop_binch10_bin0,prob_binch12_bin0,prob_binch13_bin1,prop_binch14_bin0,prop_binch16_bin17"
#autoMCStats are handled by combines Nuisnace group itself!!

all="${rates},${yields},${hammer},${bs_prop},${datamc},${others}"

if [[ $fittype == "asimov" ]]; then

  echo "ASIMOV LIKELIHOOD SCANS"

  ###########################################
  ### run 1D fit for rDs with rDsStar float #
  ###########################################
  ##
  combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit -n _1D_scan_rDs_float_all_$datetime  
  plot1DScan.py higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ############################################################
  ### run 1D fit for rDs with rDs float and different fixed #
  ############################################################
  #
  #combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters     $hammer     -n _1D_scan_rDs_freeze_hammer_$datetime
  combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit  --freezeParameters $all  -n _1D_scan_rDs_freeze_bbb_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDs_freeze_hammer_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_hammer_$datetime  --main-label "Freeze FF uncert." \
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_bbb_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_bbb_$datetime  --main-label "stat. + bbb." \
  # 
  ###########################################################
  ### run 1D fit for rDs with rDs float and all   fixed #
  ###########################################################
  ##
  combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all --freezeNuisanceGroups autoMCStats  -n _1D_scan_rDs_freeze_all_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_all_$datetime  --main-label "Stat. only" \

  ##############################
  #### overlay all likelihoods #
  ##############################
 
  plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_overlay_likelihoods_$datetime  --main-label "Stat. only" \
  --others "higgsCombine_1D_scan_rDs_freeze_bbb_${datetime}.MultiDimFit.mH120.root:Freeze bbb.:4" "higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 
  #--others "higgsCombine_1D_scan_rDs_freeze_hammer_${datetime}.MultiDimFit.mH120.root:Freeze FF uncert.:4" "higgsCombine_1D_scan_rDs_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 

  ###########################################
  ### run 1D fit for rDsStar with rDs float #
  ###########################################
  ##
  combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit -n _1D_scan_rDsStar_float_all_$datetime 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_float_all_$datetime  --main-label "Asimov" --main-color=4 \

  ############################################################
  ### run 1D fit for rDsStar with rDs float and hammer fixed #
  ############################################################
  #
  #combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $hammer -n _1D_scan_rDsStar_freeze_hammer_$datetime
  combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit  --freezeParameters $all -n _1D_scan_rDsStar_freeze_bbb_$datetime
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_hammer_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_hammer_$datetime  --main-label "Freeze FF uncert." \
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_bbb_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_bbb_$datetime  --main-label "stat. + bbb." \
  # 
  ###########################################################
  ### run 1D fit for rDsStar with rDs float and all   fixed #
  ###########################################################
  ##
  combine -M MultiDimFit ./my_workspace_binned_${datetime}.root --algo grid --points 300 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1 -t -1 -v 1  --setParameters rDs=$rDsInit,rDsStar=$rDsStarInit --freezeParameters $all --freezeNuisanceGroups autoMCStats  -n _1D_scan_rDsStar_freeze_all_$datetime
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_all_$datetime  --main-label "Stat. only" \

  #############################
  ### overlay all likelihoods #
  #############################
 
  plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_${datetime}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_overlay_likelihoods_$datetime  --main-label "Stat. only" \
  --others "higgsCombine_1D_scan_rDsStar_freeze_bbb_${datetime}.MultiDimFit.mH120.root:Freeze bbb.:4" "higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 
  #--others "higgsCombine_1D_scan_rDsStar_freeze_hammer_${datetime}.MultiDimFit.mH120.root:Freeze FF uncert.:4" "higgsCombine_1D_scan_rDsStar_float_all_${datetime}.MultiDimFit.mH120.root:Asimov:2" 
 
else

  echo "blub"
  #########################################
  # run 1D fit for rDsStar with rDs float #
  #########################################
  combine -M MultiDimFit ./my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1  -v 1  -n _1D_scan_rDsStar_float_all_data_blind_$datetime${blind} 
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
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDsStar --floatOtherPOIs 1  -v 1 --freezeParameters $all --freezeNuisanceGroups autoMCStats -n _1D_scan_rDsStar_freeze_all_data_blind_$datetime${blind}
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_freeze_all_data_blind_$datetime${blind}  --main-label "Stat. only" \
  ############################
  ## overlay all likelihoods #
  ############################
  #plot1DScan.py higgsCombine_1D_scan_rDsStar_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDsStar -o 1D_scan_rDsStar_overlay_likelihoods_data_blind_$datetime${blind}  --main-label "Stat. only" \
  #--others "higgsCombine_1D_scan_rDsStar_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2"
  #--others "higgsCombine_1D_scan_rDsStar_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2" "higgsCombine_1D_scan_rDsStar_freeze_bbb_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Freeze bbb:4" 


  
  ##########################################
  ## run 1D fit for rDs with rDs float #
  ##########################################
  combine -M MultiDimFit ./my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1  -n _1D_scan_rDs_float_all_data_blind_$datetime${blind}
  plot1DScan.py higgsCombine_1D_scan_rDs_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_float_all_data_blind_$datetime${blind}  --main-label "Data blind" --main-color=4 \
  ############################################################
  ### run 1D fit for rDs with rDs float and hammer fixed #
  ############################################################
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 300 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1  --freezeParameters $hammer -n _1D_scan_rDs_freeze_hammer_data_blind_$datetime${blind}
  #plot1DScan.py higgsCombine_1D_scan_rDs_freeze_hammer_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_hammer_data_blind_$datetime${blind}  --main-label "Freeze Hammer" \
  ##########################################################
  ## run 1D fit for rDsStar with rDs float and bbb fixed #
  ##########################################################
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1 --freezeNuisanceGroups autoMCStats -n _1D_scan_rDs_freeze_bbb_data_blind_$datetime${blind}
  #plot1DScan.py higgsCombine_1D_scan_rDs_freeze_bbb_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_bbb_data_blind_$datetime${blind}  --main-label "Freeze bbb" \
  ###########################################################
  ### run 1D fit for rDs with rDs float and all   fixed #
  ###########################################################
  #combine -M MultiDimFit my_workspace_binned_${datetime}${blind}.root --algo grid --points 200 --saveInactivePOI 1 -P rDs --floatOtherPOIs 1  -v 1 --freezeParameters $all --freezeNuisanceGroups autoMCStats -n _1D_scan_rDs_freeze_all_data_blind_$datetime${blind}
  #plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_freeze_all_data_blind_$datetime${blind}  --main-label "Stat. only" \
  ##############################
  #### overlay all likelihoods #
  ##############################
  #plot1DScan.py higgsCombine_1D_scan_rDs_freeze_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root --POI rDs -o 1D_scan_rDs_overlay_likelihoods_data_blind_$datetime${blind}  --main-label "Stat. only" \
  #--others "higgsCombine_1D_scan_rDs_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2" 
  #--others "higgsCombine_1D_scan_rDs_float_all_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Data blind:2" "higgsCombine_1D_scan_rDs_freeze_bbb_data_blind_${datetime}${blind}.MultiDimFit.mH120.root:Freeze bbb:4" 

fi



