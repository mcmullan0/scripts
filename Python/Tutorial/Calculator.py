# A calculator designed by Mark

Open=1
a=0
while Open==1:
  print "\nOption 1 - add"
  print "Option 2 - subtract"
  print "Option 3 - multiply"
  print "Option 4 - divide"
  print "\nOption 5 - quit program"
  a=input("\nWhat kind of calculation would you like to do?")
  # Addition
  if a==1:
    print "enter two numbers (use return after each)"
    add1=input("Add this: ")
    add2=input("to this: ")
    print add1, "+", add2, "=", add1+add2
    #Subtraction
  elif a==2:
    print "enter two numbers (use return after each)"
    add2=input("Subtract this: ")
    add1=input("from this: ")
    print add1, "-", add2, "=", add1-add2
    #Multiplication
  elif a==3:
    print "enter two numbers (use return after each)"
    add1=input("Multiply this: ")
    add2=input("to this: ")
    print add1, "x", add2, "=", add1*add2
    #Division
  elif a==4:
    print "enter two numbers (use return after each)"
    add1=input("Divide this: ")
    add2=input("by this: ")
    print add1, "/", add2, "=", add1/add2
    #Close program
  else:
    print "Goodbye"
    Open=0
