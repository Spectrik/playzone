#!/usr/bin/env python

import xml

# Our descriptor class
class ExternalStorage:

    __slots__ = ("attribute_name",)
    __storage = {}

    def __init__(self, attribute_name):
        self.attribute_name = attribute_name

    def __set__(self, instance, value):
        self.__storage[id(instance), self.attribute_name] = value

    def __get__(self, instance, owner=None):
        if instance is None:
            return self
        return self.__storage[id(instance), self.attribute_name]

class Point:
    __slots__ = ()
    x = ExternalStorage("x")
    y = ExternalStorage("y")

    def __init__(self, x=0, y=0):
        self.x = x
        self.y = y


bodA = Point(20, 35)
print(bodA.x)

### Another example
class XmlShadow:
    
    def __init__(self, attribute_name):
        self.attribute_name = attribute_name

    def __get__(self, instance, owner=None):
        return xml.sax.saxutils.escape(getattr(instance, self.attribute_name))

class Product:
    __slots__ = ("_name", "description", "price")

    name_as_xml = XmlShadow("name")
    description_as_xml = XmlShadow("description")

    def __init__(self, name, description, price):
        self._name = name
        self.description = description
        self.price = price

product = Product("Dláto <3cm>", "Dláto & násada", 45.25)
print(product._name, product.name_as_xml, product.description_as_xml)

