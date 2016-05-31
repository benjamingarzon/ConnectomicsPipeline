#!/usr/bin/env python
import sys
import csv

tabin = csv.reader(sys.stdin, dialect=csv.excel_tab)
commaout = csv.writer(sys.stdout, dialect=csv.excel)
for row in tabin:
    if row[-1]=="":
        row = row[:-1]    
    commaout.writerow(row)

