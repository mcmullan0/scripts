#! /usr/bin/python
# The A.2 simuPOp example 
import simuOpt
simuOpt.setOptions(optimized=False, debug='DBG_WARNING')
import simuPOP as sim
pop = sim.Population(size=[20, 30], loci=[10, 20], lociPos=list(range(20, 50)),
	lociNames=['loc1_%d' % x for x in range(1, 11)] +
		['loc2_%d' % x for x in range(1, 21)],
	alleleNames=['A', 'C', 'G', 'T'], infoFields='a')
pop.ploidy()
2
pop.numChrom()
2
pop.numloci(1)
10
pop.chromBegin(1)
10
pop.chromEnd(1)
30
pop.totNumLoci()
30
pop.chromLocusPair(22) #Chromosome number and relative index
(1, 12)
pop.locusName(22)
'loc2_13'
pop.lociByNames(['loc1_4', 'loc2_2'])
(3, 11)
pop.alleleName(1)
'C'
pop.locusPos(15)
35.0
pop.infoFields()
('a',)
pop.infoField(0)
'a'
