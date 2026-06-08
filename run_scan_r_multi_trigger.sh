#!/bin/bash


# variable we fit
export var=$1

# variable in which we bin
export splitter=$2

#dt of the datacards
export datetime_mu7=$3
export datetime_mu9=$4
datetime="${datetime_mu7}_and_${datetime_mu9}"

# if given, run blind  data fit
export data=$5

#make dir to save stuff
mkdir -p ./$datetime
mkdir -p ./$datetime/scan_r/

#since combine can not save into directories, copy the .sh file into the directory and fit inside there
cp scan_r_multi_trigger.sh ./$datetime/scan_r/
cd ./$datetime/scan_r/

#perform fit!
./scan_r_multi_trigger.sh $var $splitter $datetime_mu7 $datetime_mu9 $data

