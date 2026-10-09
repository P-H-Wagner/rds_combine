import json
import argparse
import os
import sys
import ROOT

########################
# FINAL FITTING SCRIPT #  
########################

parser = argparse.ArgumentParser()
parser.add_argument("--datetime", required = True,        help = "Specify datetime")
parser.add_argument("--impacts" , action="store_true",    help = "Specify datetime")
parser.add_argument("--scans"   , action="store_true",    help = "Specify datetime")
parser.add_argument("--gof"     , action="store_true",    help = "Specify datetime")
parser.add_argument("--diag"    , action="store_true",    help = "Specify datetime")
parser.add_argument("--all"     , action="store_true",    help = "Specify datetime")
args = parser.parse_args()

if args.all:
  args.impacts = True
  args.scans   = True
  args.gof     = True
  args.diag    = True

# variables
rDsInit="0.297"
rDsStarInit="0.245"
path="/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/"

# create workspace
cmd  = f"/cvmfs/cms.cern.ch/common/cmssw-el7 --bind /pnfs:/pnfs --bind /work:/work "
cmd += f"--command-to-run "
cmd += f"'cd /work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine "
cmd += f" && ./create_workspace.sh combo {args.datetime} asimov {rDsInit} {rDsStarInit} "
cmd += f" && ./create_workspace.sh combo {args.datetime} data   {rDsInit} {rDsStarInit}'"
#cmd += f" && ./create_workspace.sh q2_coll {args.datetime} asimov {rDsInit} {rDsStarInit} "
#cmd += f" && ./create_workspace.sh q2_coll {args.datetime} data   {rDsInit} {rDsStarInit}'"

print(cmd)
os.system(cmd)
print(" ====> WORKSPACE created")

# extract parametres and nuisances
cmd  = f"/cvmfs/cms.cern.ch/common/cmssw-el7 --bind /pnfs:/pnfs --bind /work:/work "
cmd += f"--command-to-run "
cmd += f"'cmsenv "
cmd += f" && python get_nuisances.py --datetime={args.datetime}' "
print(cmd)
os.system(cmd)
print(" ====> NUISANCE LIST + PARAMETERS extracted")


if args.impacts:

  ###########
  # IMPACTS #
  ###########
  
  #initial fits
  
  cmd  = f"/cvmfs/cms.cern.ch/common/cmssw-el7 --bind /pnfs:/pnfs --bind /work:/work "
  cmd += f"--command-to-run "
  cmd += f"'cmsenv " 
  cmd += f" && cd {path}/{args.datetime}"
  cmd += f" && combineTool.py -M Impacts -d ./my_workspace_binned_{args.datetime}.root -m 125 -n .impacts_rDs_{args.datetime}     --redefineSignalPOIs rDs     --setParameters rDsStar=${rDsStarInit} --floatParameters rDsStar --cminDefaultMinimizerStrategy 0 -t -1 --doInitialFit " # for rDs
  cmd += f" && combineTool.py -M Impacts -d ./my_workspace_binned_{args.datetime}.root -m 125 -n .impacts_rDsStar_{args.datetime} --redefineSignalPOIs rDsStar --setParameters rDs=${rDsInit}         --floatParameters rDs     --cminDefaultMinimizerStrategy 0 -t -1 --doInitialFit " # for rDsStar
  cmd += f" && cd {path}/{args.datetime}_blind"
  cmd += f" && combineTool.py -M Impacts -d ./my_workspace_binned_{args.datetime}_blind.root -m 125 -n .impacts_data_{args.datetime}    --cminDefaultMinimizerStrategy 0 -P rDs -P rDsStar --doInitialFit '" # data
  os.system(cmd)
  print(" ====> INITIAL FITS done")
  
  # fit along every nuisance
  
  with open(f"{args.datetime}/parameters_{args.datetime}.json","r") as f:
    paras = json.load(f)
  
  os.system("mkdir -p ./{args.datetime}/impacts/")
  for param in paras:
  
    cmd  = f"sbatch -p short -o ./{args.datetime}/impacts/impact_{param}.txt -e ./{args.datetime}/impacts/impact_{param}.txt --job-name=IMPACT_{param}_{args.datetime} "
    cmd += f"impacts.sh {args.datetime} {rDsInit} {rDsStarInit} {param}"
    print(cmd)
    os.system(cmd)
  
  print(" ====> IMPACTS submitted ")

if args.scans:

  #####################
  ## LIEKLIHOOD SCANS # 
  #####################
  
  #cmd  = f"sbatch -p short -o ./{args.datetime}/scan_data_log.txt -e ./{args.datetime}/scan_data_err.txt --job-name=SCAN_DATA{args.datetime} "
  #cmd += f"scan_likelihoods.sh {args.datetime} data {rDsInit} {rDsStarInit} "
  #print(cmd)
  #os.system(cmd)
  #print(" ====> LIKELIHOOD SCAN done")
  
  cmd  = f"sbatch -p short -o ./{args.datetime}/scan_log.txt -e ./{args.datetime}/scan_err.txt --job-name=SCAN_{args.datetime} "
  cmd += f"scan_likelihoods.sh {args.datetime} asimov {rDsInit} {rDsStarInit} "
  print(cmd)
  os.system(cmd)
  print(" ====> LIKELIHOOD SCAN done")

if args.gof:
  
  ###################
  # GOODNESS OF FIT #
  ###################
  cmd  = f"sbatch -p short -o ./{args.datetime}/gof_log.txt -e ./{args.datetime}/gof_err.txt --job-name=GOF_{args.datetime} "
  cmd += f"gof.sh {args.datetime} {rDsInit} {rDsStarInit} "
  print(cmd)
  os.system(cmd)
  print(" ====> GOF done")

if args.diag:
  
  ###################
  # FIT DIAGNOSTICS #
  ###################
  
  cmd  = f"sbatch -p short -o ./{args.datetime}/diag_log.txt -e ./{args.datetime}/diag_err.txt --job-name=DIAG_{args.datetime} "
  cmd += f"diag.sh {args.datetime} {rDsInit} {rDsStarInit} "
  print(cmd)
  os.system(cmd)
  print(" ====> DIAGNOSTICS done")
  
  
  
  
