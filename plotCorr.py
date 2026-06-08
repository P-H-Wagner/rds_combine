import uproot
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

file = uproot.open("robustHesse_1D_scan_rDsStar_with_all_float_hesse.root")
h = file["h_correlation"]

# get matrix (it is symmetric!)
matrix = h.values()

# get labels
labels = h.axes[0].labels()

cmap = sns.diverging_palette(220, 10, as_cmap=True)
sns.heatmap(matrix, xticklabels=labels, yticklabels=labels, cmap=cmap, vmax=1., vmin=-1, center=0, annot=True, fmt='.1f', square=True, linewidths=.8, cbar_kws={"shrink": .8},  annot_kws={"size": 2})
plt.savefig("correlation_matrix.pdf")
