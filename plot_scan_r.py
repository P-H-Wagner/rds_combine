import numpy as np
import ROOT
import glob
import matplotlib.pyplot as plt

files_rds   = glob.glob("./*asimov_fit_rDs_*.root")
files_rdsst = glob.glob("./*asimov_fit_rDsStar_*.root")

#load as rdf

rds_central   = []
rds_down      = []
rds_up        = []
rdsst_central = []
rdsst_down    = []
rdsst_up      = []

rds_r         = []
rdsst_r       = []

for (f_rds,f_rdsst) in zip(files_rds,files_rdsst):
  print(f_rds)
  rds_r  .append(float(f_rds  .split("scan_r_at_")[1].split(".MultiDimFit")[0]))
  rdsst_r.append(float(f_rdsst.split("scan_r_at_")[1].split(".MultiDimFit")[0]))

  rdf_rds   = ROOT.RDataFrame("limit",f_rds  )
  rdf_rdsst = ROOT.RDataFrame("limit",f_rdsst)

  #convert to numpy
  np_rds    = rdf_rds  .AsNumpy()
  np_rdsst  = rdf_rdsst.AsNumpy()

  #extract the r value and the uncertainties
  rds_central   .append( np_rds["rDs"][0]        )
  rds_down      .append( np_rds["rDs"][1]        )
  rds_up        .append( np_rds["rDs"][2]        )

  rdsst_central .append( np_rdsst["rDsStar"][0]  )
  rdsst_down    .append( np_rdsst["rDsStar"][1]  )
  rdsst_up      .append( np_rdsst["rDsStar"][2]  )

#get rel error
rds_up     = [ up - central   for up,central   in zip(rds_up,     rds_central)]
rds_down   = [ central - down for down,central in zip(rds_down,   rds_central)]
rdsst_up   = [ up - central   for up,central   in zip(rdsst_up,   rdsst_central)]
rdsst_down = [ central - down for down,central in zip(rdsst_down, rdsst_central)]

#now we plot :-)
plt.errorbar(rds_r,rds_central,yerr=[rds_down,rds_up], marker ="+", color="k", ecolor="red")
plt.title(r"Asimov with second ratio as floating nuisance ")
plt.xlabel(r"POI $R(D_{s})$")
plt.ylabel(r"Postfit value + uncertainty")

#plt.ylim(min(rds_r)*0.5, max(rds_r) * 1.5)

plt.savefig("scan_rds_poi_asimov.pdf")


plt.errorbar(rdsst_r,rdsst_central,yerr=[rdsst_down,rdsst_up], marker ="+", color="k", ecolor="red")

plt.title(r"Asimov with second ratio as floating nuisance ")
plt.xlabel(r"POI $R(D^*_{s})$")
plt.ylabel(r"Postfit value + uncertainty")

#plt.ylim(min(rdsst_r)*0.5, max(rdsst_r) * 1.5)

plt.savefig("scan_rdsst_poi_asimov.pdf")

