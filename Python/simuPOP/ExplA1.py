#! /usr/bin/python
# The A.1A simuPOp example

# Use simuOpt to import options
import simuOpt
simuOpt.setOptions(quiet=True, numThreads=4, gui=True)

#This simuOpt allows selection of one of the six simuPOP modules
#setOptions(optimized=False, alleleType='long', quiet=True)

import simuPOP as sim
# Set up th epopulation, ploidy is 2 by default, add (1000)*5 to make
# 5 populations
pop = sim.Population(size=1000, loci=2)
pop.evolve(
	initOps=[
		# Initialize individuals with random sex (MALE or FEMALE)
		sim.InitSex(),
		# Initialize individuals with two haplotypes.
		sim.InitGenotype(haplotypes=[[1, 2], [2, 1]])
	],
	# Random mating using a recombination operator
	matingScheme=sim.RandomMating(ops=sim.Recombinator(rates=0.01)),
	postOps=[
		# Calculate Linkage Disequilibrium between two loci
		sim.Stat(LD=[0, 1], step=10),
	# Print calculated LD values
		sim.PyEval(r"'%2d: %.2f\n' % (gen, LD[0][1])", step=10),
	],
	gen=100
)
