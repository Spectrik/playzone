#!/usr/bin/python3

# TODO: Parsing arguments & Configuration

import sys
import socket
import logging
import time
import os

# Set the level of logging
logging.basicConfig(level="INFO")

class Raspotify:
    
    def __init__(self):
        """ Constructor """

        # Allowed options
        self.allowed_opts = ("next", "previous", "pause", "stop")

        # Socket path
        self.socket = '/var/run/raspotify.sock'

        # Spotify playlist uri
        self.playlist_uri = ""

        # Buffer size
        self.buffer_size = 2

    def play_next_song(self):
        pass
    
    def play_previous_song(self):
        pass

    def pause_playback(self):
        pass
    
    def start_playback(self):
        pass
    
    def create_socket(self):
        """ Create the UDS socket """

        # Make sure the socket does not already exist
        try:
            os.unlink(self.socket)
        except OSError:
            if os.path.exists(self.socket):
                raise

        # Create a Unix Domain Socket
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        
        # Bind socket
        print('Starting up on %s' % self.socket)
        sock.bind(self.socket)

        # Return the socket
        return sock

    def process_data(self, data):
        """ Process incoming socket data """

        # Convert input to str
        try:
            command = str(data)
            command = command.lower()
        except Exception as e:
            print(e)
            
        # Is it an allowed command?
        if command in self.allowed_opts:

            # Run the command
            self.run_command(command)
        else:
            print("Unknown command: " + command)

    def run_command(self, command):
        """ Run the specific command """
        
        if command == "next":
            self.pause_playback()
        elif command == "previous":
            self.play_previous_song()
        elif command == "pause":
            self.pause_playback()
        elif command == "stop":
            self.start_playback()

    def run(self):
        """ Main function """
        
        # Log info
        logging.info("Starting the main loop.")

        # Get the socket
        socket = self.create_socket()        

        # Start listening
        socket.listen(1)

        # Infinite loop
        while True:
            
            # (Re)initialize command variable
            command = ''
            
            # Wait for a connection
            logging.debug('Waiting for a connection...')
            connection, client_address = socket.accept()
            
            try:
                logging.debug('Connection from: ' + client_address)

                # Receive the data in small chunks and retransmit it
                while True:
                    data = connection.recv(self.buffer_size)

                    # Build the whole message
                    if data:
                        command += str(data.decode("utf-8"))  
                    else:
                        # End of the data stream
                        self.process_data(command)
                        break
            finally:
                # Clean up the connection
                logging.debug("Closing the connection!")
                connection.close()

# Create the object
mainObj = Raspotify()

# Run the shit!
mainObj.run()
