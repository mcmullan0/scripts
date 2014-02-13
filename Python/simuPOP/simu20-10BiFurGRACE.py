#! /usr/bin/python
# This version comes from PythonTEST6.1.py

import simuOpt
simuOpt.setOptions(numThreads=12, quiet=True, alleleType='long')
import simuPOP as sim
from simuPOP.utils import importPopulation, export
from simuPOP.sampling import drawRandomSample

#g = 5000	# gen
#u = 1e-6	# u
#m = 0		# m
#c = 400000	# contig
#r = 1/c	# recomb
#print "\nMutation rate =", u
#print "\nMigration rate =", m
#print "\n",g, "Generations"
#print "\nContig size =", c
#print "\nRecombination rate =", r, "\n"


pop = sim.Population(size=[10], ploidy=2, loci=400000, chromNames=['Chr1'], # Find out whether simuPOP 'thinks' all these loci are on the same chromosome
  alleleNames=['A', 'C', 'T', 'G'],
  infoFields=['migrate_to']) 
pop.evolve(
  initOps=[
    sim.InitSex(maleFreq=0.5),
    sim.InitGenotype(freq=[0.25, 0.25, 0.25, 0.25])
    ],
  preOps=[
    sim.AcgtMutator(rate=[1e-6], model='JC69'),
    sim.PyEval(r"'\nGen %2d\n' % (gen)", step=1000),
    sim.Stat(alleleFreq=[0, 1, 2]),
    sim.SplitSubPops(subPops=0, sizes=[100]*2, at=1000),
    sim.SplitSubPops(subPops=0, sizes=[40, 60], at=1100),
    sim.SplitSubPops(subPops=2, sizes=[40, 60], at=1200),
    sim.SplitSubPops(subPops=1, sizes=[20, 40], at=1300),
    sim.SplitSubPops(subPops=4, sizes=[20, 40], at=1400),
    sim.SplitSubPops(subPops=3, sizes=[20]*2, at=1500),
    sim.SplitSubPops(subPops=0, sizes=[20]*2, at=1600),
    sim.SplitSubPops(subPops=3, sizes=[20]*2, at=1700),
    sim.SplitSubPops(subPops=8, sizes=[20]*2, at=1800),
    sim.PyEval(r"', '.join(['%.3f' % alleleFreq[0][x] for x in range(4)]) + '\n'", step=1000),
    sim.PyEval(r"', '.join(['%.3f' % alleleFreq[1][x] for x in range(4)]) + '\n'", step=1000),
    sim.PyEval(r"', '.join(['%.3f' % alleleFreq[2][x] for x in range(4)]) + '\n'", step=1000),
    sim.Stat(popSize=True, step=1000),
    sim.PyEval(r'"PreMig: %s\n" % subPopSize', step=1000),
#    sim.Migrator(rate=[
#      [0, m, m, m, m, m, m, m, m, m],
#      [m, m, 0, m, m, m, m, m, m, m],
#      [m, m, m, 0, m, m, m, m, m, m],
#      [m, m, m, m, 0, m, m, m, m, m],
#      [m, m, m, m, m, 0, m, m, m, m],
#      [m, m, m, m, m, m, 0, m, m, m],
#      [m, m, m, m, m, m, m, 0, m, m],
#      [m, m, m, m, m, m, m, m, 0, m],
#      [m, m, m, m, m, m, m, m, m, 0]
#    ], begin=1000),
    sim.Stat(popSize=True, step=1000),
    sim.PyEval(r'"PreSex: %s\n" % subPopSize', step=1000)
  ],
  matingScheme=sim.RandomMating(ops=sim.Recombinator(rates=[0.25e-6])), # add SbPSz(pop, gen) here , subPopSize=SbPSz
  postOps=[
    sim.ResizeSubPops(proportions=[20], begin=50, end=50),
    sim.Stat(popSize=True, step=1000),
    sim.PyEval(r'"PstSex: %s\n" % subPopSize', step=1000),
  ],
  finalOps=[
  ],
  gen=25000
)
sample = drawRandomSample(pop, sizes=[1]*10)
sim.utils.saveCSV(sample, filename='replacetext'),
