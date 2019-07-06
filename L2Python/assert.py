#!/usr/bin/env python

# assert statement has a condition or expression which is supposed to be always true. 
# If the condition is false assert halts the program and gives an AssertionError.

def avg(marks):
        assert len(marks) != 0,"List is empty."
        return sum(marks)/len(marks)
    
mark2 = [55,88,78,90,79]
print("Average of mark2:",avg(mark2))
    
mark1 = []
print("Average of mark1:",avg(mark1))
