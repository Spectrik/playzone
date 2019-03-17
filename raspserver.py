#!/usr/bin/python

from SocketServer import UnixStreamServer, StreamRequestHandler
import logging
import socket

class MyHandler(StreamRequestHandler):
    """ Handler class for the UnixStreamServer class """

    # Handle the connection
    def handle(self):

        # Get the data
        self.data = self.rfile.readline().strip()

        # Return the result
        return self.data

class MyServer(UnixStreamServer):
    """ Unix stream socket server """

    def __init__(self, server_address, handler_cls):

         # File descriptor for getting socket info by systemd
        self.systemd_socket_fd = 3

        # Invoke base but omit bind/listen steps (performed by systemd activation!)
        UnixStreamServer.__init__(self, server_address, handler_cls, bind_and_activate=False)
        
        # Override socket with our, systemd one
        self.socket = socket.fromfd(self.systemd_socket_fd, self.address_family, self.socket_type)