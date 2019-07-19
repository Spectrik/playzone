#!/usr/bin/env python

### Classmethods example
### Class methods are methods that automatically take the class as the first argument.
### Class methods can also be used as alternative constructors.

class Employee:

    num_of_emps = 0
    raise_amt = 1.04

    def __init__(self, first, last, pay):
        'Constructor'
        self.first = first
        self.last = last
        self.pay = pay
        self.email = first + '.' + last + '@email.com'

        Employee.num_of_emps += 1

    def fullname(self):
        'Return the full name'
        return '{} {}'.format(self.first, self.last)
    
    def apply_raise(self):
        'You got yourself a raise!'
        self.pay = int(self.pay * self.raise_amt)

    @classmethod
    def set_raise_amt(cls, amount):
        'Change the class variable containing fixed raise rate'
        cls.raise_amt = amount

    @classmethod
    def create_from_string(cls, string):
        'Create an employee instance class from a string'
        first, last, pay = string.split('-')
        return cls(first, last, pay)

# Test it
emp1 = Employee('Ondrej', 'Janas', 1000000)
emp2 = Employee('Amanda', 'Stramanda', 100)

print("Before rate change")
print(Employee.raise_amt)
print(emp1.raise_amt)
print(emp2.raise_amt)

# Change the raise rate
Employee.set_raise_amt(1.07)

print("After rate change")
print(Employee.raise_amt)
print(emp1.raise_amt)
print(emp2.raise_amt)


### Create an employee class instance from string

empstr1 = 'John-Doe-70000'
empstr2 = 'Steve-Smith-30000'

# Dummy approach
first, last, pay = empstr1.split('-')
newempstr1 = Employee(first, last, pay)

# Better aproach
newempstr2 = Employee.create_from_string(empstr2)
