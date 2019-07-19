#!/usr/bin/env python

# *
def foo(x, y, z):
    print("First is ", x, " then ", y, " lastly ", z)
 
a = [1, 50, 99]
 
foo(*a)
# First is 1 then 50 lastly 99
 
b = [[55,66,77], 88, 99]
foo(*b)
# First is [55,66,77] then 88 lastly 99
 
d = {"y": 23, "z": 56, "x": 15}
 
foo(*d)
# This passes in the keys of the dict
# First is z then x lastly y

# **
def bar(x, y, z):
    print("First is ", x, " then ", y, " lastly ", z)
 
d = {"y": 23, "z": 56, "x": 15}
 
bar(*d)
# Works, but not what you wanted
# First is z then x lastly y
 
bar(**d)
# First is 15 then 23 lastly 56