#!/usr/bin/env python

### Decorator is a function which takes another function as an argument

### Closures example
def outer_function(msg):

    def inner_function():
        print(msg)
    
    return inner_function  ### () is a call operator
    
hi_func = outer_function("Hi!")
bye_func = outer_function("Bye!")

hi_func()
bye_func()


# Decorator function
def decorator_function(original_function):
    def wrapper_function(*args, **kwargs):
        print("Wrapper executed this before {}".format(original_function.__name__))
        return original_function(*args, **kwargs)
    return wrapper_function

# Function to be decorated
def display():
    print("Display function ran!")

# Get the wrapper function waiting to be executed into a variable
decorated_display = decorator_function(display)

# Run it
decorated_display()

### The other way to call a decorator on our function is this:

@decorator_function    ## This is equivalent to decorated_display = decorator_function(display)
def display():
    print("Display function ran!")

# Run it
display()

### Another function which wants to be decorated but takes 2 args
@decorator_function
def display_info(name, age):
    print("Display_info ran with argument ({}, {})".format(name, age))

# Run it
display_info("John", 25)


# Class as a decorator

class decorator_class(object):

    def __init__(self, original_function):
        self.original_function = original_function

    def __call__(self, *args, **kwargs):
        print("call method executed this before {}".format(self.original_function.__name__))
        return self.original_function(*args, **kwargs)

@decorator_class
def display_info(name, age):
    print("Display_info ran with argument ({}, {})".format(name, age))

# Run it

display_info("Ondra", 27)

### Useful example of decorators

# - logging that function was ran, how many times, when and with what args -> Decorator function would act as logger
# - timing for how long function ran
