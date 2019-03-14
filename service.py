#!/usr/bin/env python

# TODO: Parsing CLI arguments & Configuration
# TODO: Tune the appropriate systemd unit
# TODO: Spotify authorization
# TODO: Drop privileges after creating the socket

import sys
import socket
import logging
import time
import spotipy
import spotipy.util as util
import os
import functions


class Raspotify:
   
    def __init__(self, username, device_id, playlist=None):
        """ Constructor """

        # Allowed options
        self.allowed_opts = ("next", "previous", "pause", "stop")

        # Socket path
        self.socket = '/var/run/raspotify.sock'

        # Spotify playlist uri
        self.playlist_uri = playlist

        # Buffer size
        self.buffer_size = 2

        # Spotify username to log in
        self.spotify_api_username = username

        # Spotify device ID to play on
        self.spotify_device_id = device_id

        # Max length of received command
        self.max_command_length = 10

        # Are we authenticated?
        self.authenticated = False

    # Authenticate to spotify webAPI
    def authenticate(self):

        try:
            token = util.prompt_for_user_token(self.spotify_api_username, "user-modify-playback-state", redirect_uri='http://localhost/')
        except spotipy.SpotifyException as e:
            logging.error(e)
            sys.exit()

        if token:
            sp = spotipy.Spotify(auth=token)
            self.authenticated = True

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
            logging.info("Unknown command: " + command)

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

        # After creating the socket, drop privileges
        functions.drop_privileges()
        
        # Authenticate
        self.authenticate()

        # Infinite loop
        while True:

            # (Re)initialize command variable
            command = ''

            # Wait for a connection
            logging.debug('Waiting for a connection...')
            connection, client_address = socket.accept()

            try:
                logging.debug('Connection from: ' + client_address)

                # Receive the data in chunks
                while True:
                    data = connection.recv(self.buffer_size)

                    # Build the whole message
                    if data:
                        command += str(data.decode("utf-8"))

                        # If someone spams us, send him to hell.
                        if len(command) > self.max_command_length:
                            logging.error("Command too long!")
                            break
                    else:
                        # End of the data stream
                        logging.debug("Received command is:" + command)
                        self.process_data(command)
                        break
            finally:
                # Clean up the connection
                logging.debug("Closing the connection!")
                connection.close()

# Main
if __name__ == "__main__":

    # Load the configuration

    # Set the level of logging
    logging.basicConfig(level="INFO")

    # Create the object
    mainObj = Raspotify("11131855676", "cfa3f1960a626bef1caeb6c2e3338db25f6d8944", "spotify:user:spotify:playlist:37i9dQZF1DX6ziVCJnEm59")

    # Run the shit!
    mainObj.run()
