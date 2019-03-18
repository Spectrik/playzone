#!/usr/bin/env python

from SocketServer import UnixStreamServer, StreamRequestHandler
import logging
import socket

class MyHandler(StreamRequestHandler):
    """ Handler class for the UnixStreamServer class """

    # Handle the connection
    def handle(self):

        # Get the data
        data = self.rfile.readline().strip()

        # Return the result
        self.server.received_data = data

class MyServer(UnixStreamServer):
    """ Unix stream socket server """

    # Getter method for received data
    def get_data(self):
        return self.received_data

    # Constructor
    def __init__(self, server_address, handler_cls):

         # File descriptor for getting socket info by systemd
        self.systemd_socket_fd = 3

        # In this property, we will store the received data
        self.received_data = ''

        # Call base constructor but omit bind / listen steps as they are performed by systemd activation
        UnixStreamServer.__init__(self, server_address, handler_cls, bind_and_activate=False)
        
        # Override socket with our, systemd one
        self.socket = socket.fromfd(self.systemd_socket_fd, self.address_family, self.socket_type)