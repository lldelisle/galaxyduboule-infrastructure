import os
import sys

def makeDicFromBed(bedFile):
  filedic={}
  chromdic={}
  startdic={}
  enddic={}
  with open(bedFile,'r') as f:
    for line in f:
      ls=line[:-1].split("\t")
      if "chr" in ls[0]:
      #This is a region
        try:
          chromdic.setdefault(ls[0], []).append(ls[3])
          startdic[ls[3]]=int(ls[1])
          enddic[ls[3]]=int(ls[2])
          filedic[ls[3]]=open("output/"+ls[3].replace(" ","_").replace("/",'_')+".bedgraph",'w')
        except IndexError:
          print(line+"This region does not have name, won't be reported.")
  return [filedic,chromdic,startdic,enddic]

os.mkdir("output")
listOfDic=makeDicFromBed(sys.argv[1])
fall=open("output/all.bedgraph",'w')
with open(sys.argv[2],'r') as f:
  for line in f:
    ls=line.split("\t")
    curchr=ls[0]
    if curchr in listOfDic[1]:
      #There is at least one region of interest which is in this chr
      curStart=int(ls[1])
      curEnd=int(ls[2])
      hasBeenReported=False
      for reg in listOfDic[1][curchr]:
        if (curEnd>listOfDic[2][reg]) & (curStart<listOfDic[3][reg]):
          #This reported coverage overlap the region reg
          listOfDic[0][reg].write(line)
          hasBeenReported=True
      if hasBeenReported:
        fall.write(line)

fall.close()
for reg in listOfDic[0]:
  listOfDic[0][reg].close()


