import ROOT
import argparse
import os
import sys
import yaml
from datetime import datetime
import matplotlib.pyplot as plt
import glob
import pdb

sys.path.append(os.path.abspath("/work/pahwagne/RDsTools/comb"))
sys.path.append(os.path.abspath("/work/pahwagne/RDsTools/help"))


ROOT.gROOT.SetBatch(True)


# processes HARDCODED ORDER (same as in prefit plotting script!!)

processes = ["data",
             "comb",
             "dsTau",
             "dsStarTau",
             "dsMu",
             "dsStarMu",
             "hb_bs_fd",
             "hb_bs_dc" ,
             "hb_b0_fd",
             "hb_b0_dc",
             "hb_bpm_fd",
             "hb_bpm_dc", 
             "hb_lambdab_fd", 
             "hb_lambdab_dc", 
             "hb_others"
             ]


colors = {"dsMu":           ROOT.kBlue - 2,
          "dsTau":          ROOT.kGreen,
          "dsStarMu":       ROOT.kCyan,
          "dsStarTau":      ROOT.kOrange,
          "hb_fd":          ROOT.kRed -7,
          "hb_dc":          ROOT.kRed -2,
          "hb_others":      ROOT.kRed -5,
          "hb_bs_fd":       ROOT.kRed +2,
          "hb_bs_dc":       ROOT.kRed -7,
          "hb_b0_fd":       ROOT.kMagenta,
          "hb_b0_dc":       ROOT.kMagenta -7,
          "hb_bpm_fd":      ROOT.kOrange + 7,
          "hb_bpm_dc":      ROOT.kOrange + 5,
          "hb_lambdab_fd":  ROOT.kViolet,
          "hb_lambdab_dc":  ROOT.kViolet-7,
          "comb":           ROOT.kGray+1,
          "data":           ROOT.kBlack}



# parsing
parser = argparse.ArgumentParser()
parser.add_argument("--file",         required = True,     help = "Specify dt of file")
parser.add_argument("--blind",        required = True,     help = "Specify blinded channels")
args = parser.parse_args()

blind_channels = [x.strip() for x in args.blind.split(",")]

def prepareCanvas():
  c1 = ROOT.TCanvas("", "", 700, 700)
  c1.Draw()
  c1.cd()
  c1.SetLeftMargin(0.16)   # <-- key fix
  c1.SetBottomMargin(0.12)

  return c1

def prepareLegend():
  leg = ROOT.TLegend(.2,.60,.88,0.88)
  leg.SetBorderSize(0)
  leg.SetFillColor(0)
  leg.SetFillStyle(0)
  leg.SetTextFont(42)
  leg.SetTextSize(0.035)
  leg.SetNColumns(2)

  return leg


def producePlots(tDir, pre_or_post):

  #number of channels
  subKeys = tDir.GetListOfKeys()
  nChan   = len(subKeys)
  
  for k in subKeys:
  
    key = k.GetName()

    drawData = True

    if key in blind_channels and pre_or_post == "postfit": 
      print(f"... skip channel {key} (blind)")
      continue 
 
    elif key in blind_channels and pre_or_post == "prefit": 
      print(f"... avoid drawing data for channel {key} (blind)")
      drawData = False 

    else:
      print(f"... Producing prefit plot for channel {key}")
  
    hs_prefit     = ROOT.THStack(f"{key}"     , f"{key}"     )
  
    #this is a directory with all histograms
    histos       = tDir.Get(key)
    histos_names = [n.GetName() for n in histos.GetListOfKeys()]
  
    #take intersection of my processes and available histos in combine
    #inter = list(set(a) & set(b))
  

    print("Starting a new canvas!")
    c1 = prepareCanvas()
    leg = prepareLegend()
 
    #pdb.set_trace()
 
    for name in processes:
  
      if name not in histos_names: 
        print(f"Remark, did not find {name} in file!"); 
        continue

      print(f"... Plotting for process {name}")
  
      #prepare the histo in the same style
      if name != "data":
        #th1d = histos.Get(name)
        th1d = histos.Get(name).Clone(f"{name}_{key}")
        th1d.SetDirectory(0)
        th1d.SetFillColor(colors[name])
        th1d.SetLineColor(colors[name])
        hs_prefit.Add(th1d)
      else:
        #obj = histos.Get(name)
        obj = histos.Get(name).Clone(f"data_{key}")
        #th1d.SetMarkerStyle(8)
        #th1d.GetYaxis().SetTitle("events")
        #th1d.GetYaxis().SetRangeUser(1e-3, th1d.GetBinContent(th1d.GetMaximumBin())*1.8)
  
        obj.SetMarkerStyle(8)
        obj.SetMarkerSize(1)
        obj.SetLineColor(ROOT.kBlack)
    
 
    total = histos.Get("total").Clone()
 

    #get the total error
    #err = histos.Get("total")
    err = histos.Get("total").Clone(f"err_{key}")
    err.SetDirectory(0)
    err.SetLineWidth(0)
    err.SetFillColor(ROOT.kBlack)
    err.SetFillStyle(3144)
    err.SetMarkerStyle(0)


    hs_prefit    .Draw("HIST")
    err.Draw("E2 SAME");

 
    #needs to be after drawing!!
    hs_prefit.GetYaxis().SetTitle("events")
    hs_prefit.SetMinimum(1e-3)
    max_y = hs_prefit.GetMaximum()
    hs_prefit.SetMaximum(max_y * 1.8)

  
    if drawData: 
      obj.Draw("EP SAME")
     
    c1.SaveAs(f"{dest}/{key}_{pre_or_post}.pdf")
 

#save at
fit  = f"/work/pahwagne/releases/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/rds_combine/"
dest = f"{fit}/{args.file}/"
os.system(f"mkdir -p {dest}")


##read file
#f = f"{fit}/fitDiagnostics_results_data.root"
#
##copy shapes file and save :))
#os.system(f"cp {f} {dest}")
#rf = ROOT.TFile.Open(f, "READ")
#
#keys = rf.GetListOfKeys()
#if len(keys) <= 0: print("Empty .root file --> ABORT"); sys.exit();
#
#for k in keys:
#  key = k.GetName()
#  print(f"... Parsing subfolder {key}")
#

#####################
# Get PREFIT SHAPES #
#####################

#read file
f = f"{fit}/fitDiagnostics_results_asimov.root"

#copy shapes file and save :))
os.system(f"cp {f} {dest}")
rf = ROOT.TFile.Open(f, "READ")

directory = rf.Get("shapes_prefit")
producePlots(directory, "prefit_asimov")

#read file
f = f"{fit}/fitDiagnostics_results_data.root"

#copy shapes file and save :))
os.system(f"cp {f} {dest}")
rf = ROOT.TFile.Open(f, "READ")

directory = rf.Get("shapes_prefit")
producePlots(directory, "prefit")
directory = rf.Get("shapes_fit_s")
producePlots(directory, "postfit")









