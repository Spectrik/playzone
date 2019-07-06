#!/usr/bin/env python

# NOTE: List is iterable but it is not an iterator

nums = [1, 2, 3]

# Loop over the number
for num in nums:
    print(num)

# Is our list iterable?
print(dir(nums))
print(iter(nums))   

# Get the iterator object of our list
i_nums = iter(nums)

# This won't work
# print(next(nums))

# This will work
print(next(i_nums))

# Write our own for loop
while True:
    try:
        item = next(i_nums)
        print(item)
    except StopIteration:
        break

# Our own iterable class
class MyRange:

    def __init__(self, start, end):
        self.value = start
        self.end = end

    def __iter__(self):
        "Return an object which has got the next method, in this case return self because the class has next method"
        return self

    def __next__(self):
        "Iterator method"
        if self.value >= self.end:
            raise StopIteration
        
        current = self.value
        self.value += 1
        return current

# Create an instance of our MyRange class
nums2 = MyRange(1, 10)

# Try to loop over it
for num in nums2:
    print(num)

