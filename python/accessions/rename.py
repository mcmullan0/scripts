#!/usr/bin/env python
import os

f = open("fastq-sample.list")
lines = f.readlines()
f.close()
counter = 0
for x in lines:
    if x[:3]=="ERS":
        header=x.replace("\n","")
    elif x[:3]=="ftp":
        #x.split("/")[7]
        os.system("mv "+x.split("/")[7].replace("\n","")+" "+header+"-"+x.split("/")[7].replace("\n",""))
    else:
        pass
    
