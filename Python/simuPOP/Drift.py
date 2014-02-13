import simuPOP as sim
def simuGeneticDrift(popSize=100, p=0.2, generations=100, replications=5):
    '''Simulate the Genetic Drift as a result of random mating.'''
    # diploid population, one chromosome with 1 locus
    # random mating with sex
    pop = Population(size=popSize, loci=[1])
    simu=Simulator(pop, rep=replications)

    if useRPy:
        plotter = VarPlotter('alleleFreq[0][0]', ylim=[0, 1], ylab='allele frequency',
            update=generations-1, saveAs='geneticDrift.png')
    else:
        plotter = NoneOp()

    # if number of generation is smaller than 200, step is 10 generations,
    # if it's between 200 and 500, set step to be 20 generations,
    # otherwise, step = 50 generations.
    if generations <= 200:
        s = 10
    elif 200 < generations <= 500:
        s = 20
    else:
        s = 50

    simu.evolve(
        # everyone initially will have the same allele frequency
        initOps = [
            InitSex(),
            InitGenotype(freq=[p, 1-p])
        ],
        matingScheme = RandomMating(),
        postOps = [
            Stat(alleleFreq=[0]),
            PyEval(r'"Generation %d:\t" % gen', reps = 0, step = s),
	        PyEval(r"'%.3f\t' % alleleFreq[0][0]", step = s),
	        PyOutput('\n', reps=-1, step = s),
	        plotter,
        ],
        gen = generations
    )

