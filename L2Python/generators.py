#!/usr/bin/env python

# Generator function
def square_numbers(nums):
    """
    Generators can save a lot of memore, we do not need to save our generated values into a list and return that list but we can return them directly
    and iterating over them without storing them to memory first. 
    """
    
    for i in nums:
        yield i*i   # yield is the keyword for generator

# Comprehension generator definition - note the rounded parantheses
my_nums2 = (x*x for x in [1, 2, 3, 4, 5])

# Get the generator into variable
my_nums = square_numbers([1, 2, 3, 4, 5])

# Try to iterate over it. One "yielded" value at a time
for my_num in my_nums:
    print(my_num)

# We get generator object here
print(my_nums)

# Converting generator into a list
list(my_nums)

# See the properties and methods of the generator
print(dir(my_nums))

# Printing one value after another of the generator
print(next(my_nums))
print(next(my_nums))
print(next(my_nums))
