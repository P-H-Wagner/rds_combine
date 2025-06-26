import numpy as np
import os
import re
import matplotlib.pyplot as plt

#get all cut subdirectories names as strings ("0.001", ... )
subdirs = [name for name in os.listdir('.') if os.path.isdir(name) and "0." in name]

sigmas = {}

cuts   = []
rDs_up       = []
rDs_down     = []
rDsStar_up   = []
rDsStar_down = []

for subdir in subdirs:

  print(f"Reading cut {subdir}")
  cuts.append(float(subdir))
  

  with open(f"./{subdir}/out.txt", "r") as f:

    lines = f.readlines()

  found = False

  for i,line in enumerate(lines):

    if "--- MultiDimFit ---" in line and "best fit parameter values and profile-likelihood uncertainties:" in lines[i+1]:

      #print("found them!")
      rDs_str     = lines[i+2]
      rDsStar_str = lines[i+3]

               
 
      rDs_up       .append( float(rDs_str    .split("/+")[1][:5] ))
      rDsStar_up   .append( float(rDsStar_str.split("/+")[1][:5] ))

      rDs_down     .append( float(rDs_str    .split("/+")[0][-5:]))
      rDsStar_down .append( float(rDsStar_str.split("/+")[0][-5:]))



      found = True
      break;


  if not found: 
    print("ALERT, no uncertainties found for this cut!!")
    cuts.pop()

# now plot!

rds_av   = [(up + down) / 2 for (up,down) in zip(rDs_up, rDs_down)]
rdsst_av = [(up + down) / 2 for (up,down) in zip(rDsStar_up, rDsStar_down)]

#plot average uncertainties for both ratios

#find minimum and cut at this minimum
min_rds_av = min(rds_av)
min_cut    = cuts[np.argmin(rds_av)]

plt.title(r" R(Ds) average $\sigma$")
plt.xlabel("Score cut")
plt.scatter(cuts,rds_av, marker = '+')
#plt.yscale("log" )
plt.ylim([min_rds_av * 0.98, min_rds_av * 1.05])  # Set ticks at desired powers of 10
plt.text(min_cut*1.01, 0.99*min_rds_av, f"Optimal cut at {min_cut}", color = "r")
plt.vlines(min_cut,min_rds_av * 0.98, min_rds_av * 1.05, color = "r")
plt.savefig("rds_av_sigma.png")
plt.clf()


min_rdsst_av = min(rdsst_av)
min_cut    = cuts[np.argmin(rdsst_av)]

plt.title(r" R(Ds*) average $\sigma$")
plt.xlabel("Score cut")
plt.scatter(cuts,rdsst_av, marker = '+')
#plt.yscale("log" )
plt.ylim([min_rdsst_av * 0.98, min_rdsst_av * 1.05])  # Set ticks at desired powers of 10
plt.text(min_cut*1.01, 0.99*min_rdsst_av, f"Optimal cut at {min_cut}", color = "r")
plt.vlines(min_cut,min_rdsst_av * 0.98, min_rdsst_av * 1.05, color = "r")
plt.savefig("rdsst_av_sigma.png")
plt.clf()
