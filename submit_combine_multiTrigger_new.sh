#!/bin/bash

#mu7="01_09_2025_09_25_38" #wout hammer sys unc
#mu7="01_09_2025_17_52_57" #including hammer sys unc (only 1 bin)
#mu9="01_09_2025_09_26_13" #wout hammer sys unc
#mu9="02_09_2025_08_26_07" #including hammer sys unc (only 1 bin)

#echo "./run_combine_multiTrigger.sh class q2_coll ${mu7} ${mu9}" 
##./run_combine_multiTrigger.sh class q2_coll ${mu7} ${mu9}

#both including binning in class variable and systematics 
#mu7="02_09_2025_12_58_23"
#mu9="02_09_2025_14_56_40" 
#
#echo "./run_combine_multiTrigger.sh score1 class ${mu7} ${mu9}" 
#./run_combine_multiTrigger.sh score1 class ${mu7} ${mu9}

#both including binning wout systematics
#mu7="02_09_2025_16_46_47"
#mu9="02_09_2025_16_46_37"

#echo "./run_combine_multiTrigger.sh class q2_coll ${mu7} ${mu9}" 
#./run_combine_multiTrigger.sh class q2_coll ${mu7} ${mu9}


#icluding binning in q2_coll and systematics
#mu9="03_09_2025_13_30_03"
#mu7="03_09_2025_13_29_55"
#echo "./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}" 
#./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}

#blinding
#mu7="04_09_2025_12_05_34"
#mu9="04_09_2025_12_05_23"
#echo "./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}" 
#./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}


#advanced binning in q2_coll and systermatics (new state of the art)
#mu7="04_09_2025_15_38_12"
#mu9="04_09_2025_14_41_44"
#echo "./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}" 
#./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}


#merging the last two bins
#mu7="05_09_2025_09_03_23"
#mu9="05_09_2025_09_04_00"
#echo "./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}" 
#./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}

#new bkg modeling
#mu7="09_09_2025_10_51_14"
#mu9="09_09_2025_10_51_18"
#
#echo "./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}" 
#./run_combine_multiTrigger.sh score1 q2_coll ${mu7} ${mu9}

#in AN v0
#mu7="09_12_2025_18_31_30"
#mu9="09_12_2025_22_53_09"

#with new bkg modeling and hb
#mu7="05_02_2026_13_00_56"
#mu9="05_02_2026_13_47_28"

#with new bkg modeling and hb and sys
#mu7="06_02_2026_08_01_18"
#mu9="06_02_2026_08_02_05"

mu7="11_02_2026_16_12_57"
mu9="11_02_2026_18_50_57"

mu7="16_03_2026_16_29_54"
mu9="16_03_2026_16_31_51"

echo "./run_combine_multiTrigger_new.sh combo ${mu7} ${mu9}" 
./run_combine_multiTrigger_new.sh combo ${mu7} ${mu9} 
