# A calculator copied from http://www.sthurlow.com/python/lesson05/, using defined
# functions

# Define main menue
def menu():
  print "\nWelcome to calculator.py"
  print "your options are:"
  print "\n1) Addition"
  print "2) Subtraction"
  print "3) Multiplication"
  print "4) Division"
  print "5) Quit calculator.py"
  return input ("\nChoose your option: ")

# Define each calculation
def add(a, b):
  print a, "+", b, "=", a+b
def sub(a, b):
  print b, "-", a, "=", b-a
def mul(a, b):
  print a, "x", b, "=", a*b
def div(a, b):
  print a, "/", b, "=", a/b

# Use menu and relavent calc to run program
Loop=1
choice=0
while Loop==1:
  choice=menu()
  if choice==1:
    add(input("Add this: "), input("to this: "))
  elif choice==2:
    sub(input("Subtract this: "), input("from this: "))
  elif choice==3:
    mul(input("Multiply this: "), input("to this: "))
  elif choice==4:
    div(input("Divide this: "), input("by this: "))
  else:
    Loop=0
print "Goodbye"
