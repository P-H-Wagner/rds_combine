#!/bin/bash


# variable we fit
export var=$1

# variable in which we bin
export splitter=$2

#dt of the datacards
export datetime=$3

# if given, run blind  data fit
export data=$4

#make dir to save stuff
mkdir -p ./$datetime
mkdir -p ./$datetime/scan_r/

#since combine can not save into directories, copy the .sh file into the directory and fit inside there
cp scan_r.sh ./$datetime/scan_r/
cd ./$datetime/scan_r/

#perform fit!
./scan_r.sh $var $splitter $datetime $data

