#! /usr/bin/python
# This version comes from PythonTEST6.1.py

import simuOpt
simuOpt.setOptions(numThreads=12, quiet=True, alleleType='long')
import simuPOP as sim
from simuPOP.utils import importPopulation, export
from simuPOP.sampling import drawRandomSample

#g = 5000	# gen
#u = 1e-6	# u
#m = 0	# m
#c = 400000	# contig
#r = 1.0/c	# recomb
#print "\nMutation rate =", u
#print "\nMigration rate =", m
#print "\n",g, "Generations"
#print "\nContig size =", c
#print "\nRecombination rate =", r, "\n"

def SbPSz(gen):
  if gen>999:
    return [20]*10
  if gen<50:
    return [10]
  else:
    return [200]

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
    sim.SplitSubPops(subPops=0, sizes=[20]*10, at=1000),
    sim.PyEval(r"', '.join(['%.3f' % alleleFreq[0][x] for x in range(4)]) + '\n'", step=1000),
    sim.PyEval(r"', '.join(['%.3f' % alleleFreq[1][x] for x in range(4)]) + '\n'", step=1000),
    sim.PyEval(r"', '.join(['%.3f' % alleleFreq[2][x] for x in range(4)]) + '\n'", step=1000),
    sim.Stat(popSize=True, step=1000),
    sim.PyEval(r'"PreMig: %s\n" % subPopSize', step=1000),
#    sim.Migrator(rate=[
#      [0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7],	# This is a chance
#      [1e-7, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7],	# based on a proportion
#      [1e-7, 1e-7, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7],
#      [1e-7, 1e-7, 1e-7, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7],
#      [1e-7, 1e-7, 1e-7, 1e-7, 0, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7],
#      [1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 0, 1e-7, 1e-7, 1e-7, 1e-7],
#      [1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 0, 1e-7, 1e-7, 1e-7],
#      [1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 0, 1e-7, 1e-7],
#      [1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 0, 1e-7],
#      [1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 1e-7, 0]
#    ], begin=1000),
    sim.Stat(popSize=True, step=1000),
    sim.PyEval(r'"PreSex: %s\n" % subPopSize', step=1000)
  ],
  matingScheme=sim.RandomMating(ops=sim.Recombinator(rates=[0.25e-6]), subPopSize=SbPSz), # add SbPSz(pop, gen) here  
  postOps=[
    sim.Stat(popSize=True, step=1000),
    sim.PyEval(r'"PstSex: %s\n" % subPopSize', step=1000),
  ],
  finalOps=[
  ],
  gen=5000
)
sample = drawRandomSample(pop, sizes=[1]*10)
sim.utils.saveCSV(sample, filename='replacetext'),
