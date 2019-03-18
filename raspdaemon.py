#!/usr/bin/env python

# import spotipy
# import spotipy.util as util
import logging
import raspserver
import functions

class RaspDaemon:
   
    def __init__(self, username, device_id, playlist=None):
        """ Constructor """

        # Allowed options
        self.allowed_opts = ("next", "previous", "pause", "stop")

        # Spotify playlist uri
        self.playlist_uri = playlist

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

        logging.debug("Trying to spotify authenticate.")

        # try:
        #     token = util.prompt_for_user_token(self.spotify_api_username, "user-modify-playback-state", redirect_uri='http://localhost/')
        # except spotipy.SpotifyException as e:
        #     logging.error(e)
        #     sys.exit()

        # if token:
        #     sp = spotipy.Spotify(auth=token)
        #     self.authenticated = True

    def play_next_song(self):
        pass
    
    def play_previous_song(self):
        pass

    def pause_playback(self):
        pass
    
    def start_playback(self):
        pass
    
    def create_server(self, host, port):
        """ Create the server handling our connections """

        # Create the server
        server = raspserver.MyServer((host, port), raspserver.MyHandler)

        # Return the server
        return server

    def process_data(self, data):
        """ Process incoming socket data """

        # Convert input to str
        try:
            command = str(data)
            command = command.lower()

            # We do not want any shit here
            if len(command) > self.max_command_length:
                logging.warn("The received command is too long!")
                return

        except Exception as e:
            print(e)

        # Is it an allowed command?
        if command in self.allowed_opts:

            # Run the command
            self.run_command(command)
        else:
            logging.warn("Unknown command: " + command)

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
        """ run function """

        # Log info
        logging.info("Starting the main loop.")
        
        # Get the server object
        try:
            server = self.create_server("localhost", 9999)
        except Exception as e:
            logging.error(e)

        # After creating the socket, drop privileges
        functions.drop_privileges()

        # Start listening for connections
        while True:
            
            # Handle each incoming connection
            try:
                server.handle_request()
                command = server.get_data()
            except Exception as e:
                logging.error(e)

            logging.debug("The command we got is: " + str(command))

            # Process the received command
            self.process_data(command)