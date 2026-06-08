from collections import defaultdict
import sys
import numpy as np

with open("/work/pahwagne/RDsTools/fit/datacards_binned/09_12_2025_18_31_30_and_09_12_2025_22_53_09/datacard_score1_in_q2_coll_regions_and_trigger_combined.txt") as f:
    #lines is a list of lists, where each sublist contains all words of one row of the txt file
    lines = [l.split() for l in f.readlines()]


#only keep the relevant lines
process  = [line for line in lines if line[0] in ["process"]]
rate     = [line for line in lines if line[0] in ["rate"]]
bins     = [line for line in lines if line[0] in ["bin"]]

#remove the "process" line which denotes the numbers -1,0,1,2,...
process = [line for line in process if line[1] not in ["-1","0","1","2","3","4","5"]]
process = process[0]  #flatten
process = process[1:] #remove first element

#flatten the rates
rate = rate[0]
rate = rate[1:] #remove first element

#remove the "bin" line which is paired with the observation line
lines_bin = [len(line) for line in bins]
max_bins  = np.argmax(lines_bin)
bins      = bins[max_bins] #already flat
bins      = bins[1:]

# collect data
table = defaultdict(dict)
for b, p, r in zip(bins, process, rate):
    table[b][p] = r

# produce LaTeX

print(r"\begin{table}[ht]")
print(r"\centering")
print(r"\begin{tabular}{||c|c|c|c|c|c|c||}")
print(r"\hline")
print(r" & dsTau & dsStarTau & dsMu & dsStarMu & hb & comb. + fakes \\")
print(r"\hline")
print(r"\hline")

for ch in table:
    dsTau     = table[ch].get("dsTau", "--")
    dsStarTau = table[ch].get("dsStarTau", "--")
    dsMu      = table[ch].get("dsMu", "--")
    dsStarMu  = table[ch].get("dsStarMu", "--")
    hb        = table[ch].get("hb", "--")
    comb      = table[ch].get("comb", "--")

    ch = ch.replace("_", "\_")

    print(f"{ch} & {dsTau} & {dsStarTau} & {dsMu} & {dsStarMu}  & {hb} & {comb} \\\\")
    print("\hline")

print(r"\hline")
print(r"\end{tabular}")
print(r"\caption{Datacard Expectation Values}")
print(r"\label{tab::appendix::datacard_content}")
print("\end{table}")


