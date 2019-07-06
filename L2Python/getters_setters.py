class Person:

    def __init__(self, name):
        self._name = name

    @property
    def name(self):
        print("Getting the name value")
        return self._name

    @name.setter
    def name(self, name):
        print("Setting name value")
        self._name = name

    # name = property(get_name, set_name)

### OR via property method

class Person:

    def __init__(self, name):
        self._name = name

    def get_name(self):
        print("Getting the name value")
        return self._name

    def set_name(self, name):
        print("Setting name value")
        self._name = name

    name = property(get_name, set_name)


# Create the object
ondra = Person("Ondra")

# Set the value
ondra.name = "Borec"

# Get the value
print(ondra.name)

# Access the value directly
ondra._name = "LUL"

# Get the value
print(ondra.name)

