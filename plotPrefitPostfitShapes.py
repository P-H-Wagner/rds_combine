import json
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
             "dsMu",
             "dsStarTau",
             "dsStarMu",
             "hb_bs_fd",
             "hb_bs_dc" ,
             "hb_b0",
             #"hb_b0_fd",
             #"hb_b0_dc",
             "hb_bpm",
             #"hb_bpm_fd",
             #"hb_bpm_dc", 
             "hb_lambdab", 
             #"hb_lambdab_fd", 
             #"hb_lambdab_dc", 
             "hb_others"
             ]



colors = {"dsMu":           ROOT.kBlue - 2,
          "dsTau":          ROOT.kBlue - 2,
          "dsStarMu":       ROOT.kCyan,
          "dsStarTau":      ROOT.kCyan,
          "hb_fd":          ROOT.kRed -7,
          "hb_dc":          ROOT.kRed -2,
          "hb_others":      ROOT.kRed -5,
          "hb_bs_fd":       ROOT.kRed +2,
          "hb_bs_dc":       ROOT.kRed -7,
          "hb_b0":          ROOT.kMagenta,
          #"hb_b0_fd":      ROOT.kMagenta,
          #"hb_b0_dc":      ROOT.kMagenta -7,
          "hb_bpm":         ROOT.kOrange + 7,
          #"hb_bpm_fd":     ROOT.kOrange + 7,
          #"hb_bpm_dc":     ROOT.kOrange + 5,
          "hb_lambdab":     ROOT.kViolet,
          #"hb_lambdab_fd": ROOT.kViolet,
          #"hb_lambdab_dc": ROOT.kViolet-7,
          "comb":           ROOT.kGray+1,
          "data":           ROOT.kBlack}

colors = { "dsMu":            ROOT.TColor.GetColor("#5790fc"), #ROOT.kBlue - 2,
           "dsTau":           ROOT.TColor.GetColor("#5790fc"), #"#ffa90e" 
           "dsStarMu":        ROOT.TColor.GetColor("#92dadd"), #ROOT.kCyan,
           "dsStarTau":       ROOT.TColor.GetColor("#92dadd"), #"#e76300" 
           "hb_fd":           ROOT.TColor.GetColor("#a96b59"), #ROOT.kRed -7,
           "hb_dc":           ROOT.TColor.GetColor("#a96b59"), #ROOT.kRed -2,
           "hb_others":       ROOT.TColor.GetColor("#94a4a2"), #ROOT.kRed -5,
           "hb_bs":           ROOT.TColor.GetColor("#7a21dd"), #ROOT.kRed +2,
           "hb_bs_fd":        ROOT.TColor.GetColor("#7a21dd"), #ROOT.kRed +2,
           "hb_bs_dc":        ROOT.TColor.GetColor("#964a8b"), #ROOT.kRed -7,
           "hb_b0":           ROOT.TColor.GetColor("#b9ac70"), #ROOT.kMagenta,
           "hb_bpm":          ROOT.TColor.GetColor("#832db6"), #ROOT.kOrange + 7,
           "hb_lambdab":      ROOT.TColor.GetColor("#a96b59"), #ROOT.kViolet,
           "comb":            ROOT.TColor.GetColor("#717581"), #ROOT.kGray+1,
           "data":            ROOT.kBlack}

legend = {"dsMu":           "B_{s}#rightarrow D_{s}#mu#nu",
          "dsTau":          "B_{s}#rightarrow D_{s}#tau#nu",
          "dsStarMu":       "B_{s}#rightarrow D*_{s}#mu#nu",
          "dsStarTau":      "B_{s}#rightarrow D*_{s}#tau#nu",
          "hb_fd":          "B^{#pm 0}_{(s)}, #Lambda_{b} #rightarrow feed-down",
          "hb_dc":          "B^{#pm 0}_{(s)}, #Lambda_{b} #rightarrow double-charm",
          "hb_others":      "other b #rightarrow D_{s} + #mu",
          "hb_bs_fd":       "B_{s} #rightarrow D_{s} + #mu (fd)",
          "hb_bs_dc":       "B_{s} #rightarrow D_{s} + #mu (cc)",
          "hb_b0":       "B^{0} #rightarrow feed-down",
          #"hb_b0_fd":       "B^{0} #rightarrow feed-down",
          #"hb_b0_dc":       "B^{0} #rightarrow double-charm",
          "hb_bpm":      "B^{#pm} #rightarrow D_{s} + #mu",
          #"hb_bpm_fd":      "B^{#pm} #rightarrow feed-down",
          #"hb_bpm_dc":      "B^{#pm} #rightarrow double-charm",
          "hb_lambdab":  "#Lambda_{b} #rightarrow D_{s} + #mu",
          #"hb_lambdab_fd":  "#Lambda_{b} #rightarrow feed-down",
          #"hb_lambdab_dc":  "#Lambda_{b} #rightarrow double-charm",
          "comb":           "Comb. + Fakes",
          "data":           "Data",
}

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
  leg = ROOT.TLegend(.2,.65,.88,0.88)
  leg.SetBorderSize(0)
  leg.SetFillColor(0)
  leg.SetFillStyle(0)
  leg.SetTextFont(42)
  leg.SetTextSize(0.030)
  leg.SetNColumns(2)

  return leg

def produceGoF(folder):

  # open json files
  with open(f"{dest}/gof_saturated_{folder}.json") as f:
    sat = json.load(f)["120.0"] #higgs mass
  with open(f"{dest}/gof_KS_{folder}.json") as f:
    ks  = json.load(f)["120.0"] #higgs mass 

  #for KS, we have one plot per category, loop over categories
  for c in ks.keys():

    print(f"====> producing GoF for category {c}")
    obs = ks[c]["obs"][0] #float
    p   = ks[c]["p"  ]    #float
    toy = ks[c]["toy"]    #list

    bins = 20
    start = min(toy+[obs])
    stop  = max(toy+[obs])

    fig, ax = plt.subplots()
    hist = plt.hist(toy, bins, (start, stop), histtype="bar", color = "b", rwidth = 0.7)
    plt.ylabel("counts")
    ymax = max(hist[0])
    #plt.vlines(obs, ymin = 0, ymax = ymax, colors = "r")
    width = 3
    ax.annotate("", xy = (obs, 0), xytext = (obs, 0.3*ymax), arrowprops=dict(arrowstyle=f"->, head_width={0.1*width}",color = "r", lw=width))

    plt.ylim(top=1.1*ymax)
    txt = f"p-value = {p}"
    ax.text(0.7, 0.95,txt,transform=ax.transAxes)

    plt.title(f"GoF - KS method - Category {c[2:]}")
    plt.savefig(f"{dest}/gof_KS_{c}.pdf")
    plt.close()

  # only one plot for saturated
  print(f"====> producing GoF for category {c}")
  obs = sat["obs"][0] #float
  p   = sat["p"  ]    #float
  toy = sat["toy"]    #list
 
  bins = 20
  start = min(toy+[obs])
  stop  = max(toy+[obs])

  fig, ax = plt.subplots()
  hist = plt.hist(toy, bins, (start, stop), histtype="bar", color = "b", rwidth = 0.7)
  plt.ylabel("counts")
  ymax = max(hist[0])
  #plt.vlines(obs, ymin = 0, ymax = ymax, colors = "r")
  width = 3
  ax.annotate("", xy = (obs, 0), xytext = (obs, 0.3*ymax), arrowprops=dict(arrowstyle=f"->, head_width={0.1*width}",color = "r", lw=width))

  plt.ylim(top=1.1*ymax)
  txt = f"p-value = {p}"
  ax.text(0.7, 0.95,txt,transform=ax.transAxes)

  plt.title(f"GoF - Saturated method ")
  plt.savefig(f"{dest}/gof_sat.pdf")
  plt.close()





def producePlots(tDir, pre_or_post):

  #number of channels
  subKeys = tDir.GetListOfKeys()
  nChan   = len(subKeys)
 
   
  for k in subKeys:
  
    key = k.GetName()

    drawData = True

    #if key in blind_channels and pre_or_post == "postfit": 
    #  print(f"... skip channel {key} (blind)")
    #  continue 
 
    #elif key in blind_channels and pre_or_post == "prefit": 
    #  print(f"... avoid drawing data for channel {key} (blind)")
    #  drawData = False 

    #else:
    #  print(f"... Producing prefit plot for channel {key}")
  
    hs_prefit     = ROOT.THStack(f"Fitting Category {key[2:]}"     , f"Fitting Category {key[2:]}"     )
  
    #this is a directory with all histograms
    histos       = tDir.Get(key)
    histos_names = [n.GetName() for n in histos.GetListOfKeys()]
  
    #take intersection of my processes and available histos in combine
    #inter = list(set(a) & set(b))
  

    print("Starting a new canvas!")
    c1 = prepareCanvas()
    leg = prepareLegend()
 
    #load here a template (DsMu) which tell us how many real bins we have  
    templates = ROOT.TFile.Open(f"/work/pahwagne/RDsTools/plots/cmsplots_binned/{args.file}/histos_DsMu_{key[2:]}.root")
    template_keys = templates.GetListOfKeys()
    #wlog we can take the first key (this is the central curve if no sys up/down)
    template_h = templates.Get(template_keys[0].GetName())
    real_bins  = template_h.GetNbinsX()

 
    for name in processes:
  
      if name not in histos_names: 
        print(f"Remark, did not find {name} in file!"); 
        continue

      print(f"... Plotting for process {name}")
  
      #pdb.set_trace()

      #prepare the histo in the same style
      if name != "data":

        #th1d = histos.Get(name)
        th1d = histos.Get(name).Clone(f"{name}_{key}")
        new_th1d = ROOT.TH1D("{name}_{key}_new","{name}_{key}_new", real_bins, 0, real_bins)
 
        #root stupid histogram starts at 1
        for i in range(1,real_bins+1):
          new_th1d.SetBinContent (i,th1d.GetBinContent(i))
          new_th1d.SetBinError   (i,th1d.GetBinError(i)  )



        th1d.SetDirectory(0)
        th1d.SetFillColor(colors[name])
        th1d.SetLineColor(colors[name])

        new_th1d.SetDirectory(0)
        new_th1d.SetFillColor(colors[name])
        new_th1d.SetLineColor(colors[name])

        #hs_prefit.Add(th1d)
        hs_prefit.Add(new_th1d)

        leg.AddEntry(new_th1d, legend[name], "F")


      else:
        #obj = histos.Get(name)
        obj     = histos.Get(name).Clone(f"data_{key}")
        #with original binning
        new_obj = ROOT.TGraphAsymmErrors()

        for i in range(real_bins):

          #extract values of graph
          x  = obj.GetX()[i]
          y  = obj.GetY()[i]
          
          exl = obj.GetEXlow()[i]
          exh = obj.GetEXhigh()[i]
          eyl = obj.GetEYlow()[i]
          eyh = obj.GetEYhigh()[i] 

          new_obj.SetPoint     (i, x, y)
          new_obj.SetPointError(i, exl, exh, eyl, eyh)


        ##write into here only non-empty bins
        #new_graph = ROOT.TGraphAsymmErrors()

        ##dont plot all the empty bins
        #ntot = obj.GetN()
        #for i in range(ntot):
        #  if (obj.GetPointY(i) < 10e-3)
  
        obj.SetMarkerStyle(8)
        obj.SetMarkerSize(1)
        obj.SetLineColor(ROOT.kBlack)
 
        new_obj.SetMarkerStyle(8)
        new_obj.SetMarkerSize(1)
        new_obj.SetLineColor(ROOT.kBlack)

        leg.AddEntry(new_obj, legend[name], "LEP")
    
 
    #total = histos.Get("total").Clone()

    #get the total error
    #err = histos.Get("total")
    err = histos.Get("total").Clone(f"err_{key}")
    new_err = ROOT.TH1D("new_err","new_err",real_bins,0,real_bins)
    for i in range(1, real_bins + 1):
      new_err.SetBinContent(i,err.GetBinContent(i))

    err.SetDirectory(0)
    err.SetLineWidth(0)
    err.SetFillColor(ROOT.kBlack)
    err.SetFillStyle(3144)
    err.SetMarkerStyle(0)

    new_err.SetDirectory(0)
    new_err.SetLineWidth(0)
    new_err.SetFillColor(ROOT.kBlack)
    new_err.SetFillStyle(3144)
    new_err.SetMarkerStyle(0)


    hs_prefit    .Draw("HIST")
    err.Draw("E2 SAME");
    leg.Draw("SAME");
    #new_err.Draw("E2 SAME");

 
    #needs to be after drawing!!
    hs_prefit.GetYaxis().SetTitle("events")
    hs_prefit.GetXaxis().SetTitle("Bin")
    hs_prefit.SetMinimum(1e-3)
    max_y = hs_prefit.GetMaximum()
    hs_prefit.SetMaximum(max_y * 1.8)

  
    if drawData: 
      #obj.Draw("EP SAME")
      new_obj.Draw("EP SAME")
     
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
f = f"{fit}/{args.file}/fitDiagnostics_results_asimov_{args.file}.root"

#copy shapes file and save :))
os.system(f"cp {f} {dest}")
rf = ROOT.TFile.Open(f, "READ")

directory = rf.Get("shapes_prefit")
producePlots(directory, "prefit_asimov")

#read file
f = f"{fit}/{args.file}_blind/fitDiagnostics_results_data_{args.file}_blind.root"

#copy shapes file and save :))
os.system(f"cp {f} {dest}")
rf = ROOT.TFile.Open(f, "READ")

directory = rf.Get("shapes_prefit")
producePlots(directory, "prefit")
directory = rf.Get("shapes_fit_s")
producePlots(directory, "postfit")


produceGoF(args.file)







