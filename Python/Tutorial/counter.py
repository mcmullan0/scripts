# This counter is a trial to see if I can get an action every 1000 generations

def grand(gen):
  gen % 1000

gen = 0
count = 1
stop = 10000
while count == 1:
  gen=gen+1
  grand=gen%1000
  if grand == 0:
    print "\nWe got to ", gen, "which is nice\n"
  if gen>stop:
    print "\n We got to 10001!\n"
    count = 0

