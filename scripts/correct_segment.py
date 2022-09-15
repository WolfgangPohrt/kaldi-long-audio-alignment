#!/usr/bin/python

# Copyright 2017  Speech Lab, EE Dept., IITM (Author: Srinivas Venkattaramanujam)

import sys

filename=sys.argv[1]
islandLength=int(sys.argv[2])

with open(filename,'r') as f:
	contents=f.read().strip()

if len(contents) < islandLength:
	island = 'C'
else:
	island='C'*islandLength




strIndex=0
list=['D','I','S']
while strIndex<len(contents):
	try:
		curr=strIndex+contents[strIndex:].index(island)
	except ValueError:
		break
	strIndex=curr+min(contents[curr:].index(i)  if i in contents[curr:] else len(contents)-curr for i in list)
	print(curr-contents[:curr].count('I'),strIndex-1-contents[:strIndex-1].count('I'))
	
