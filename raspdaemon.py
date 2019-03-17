#!/usr/bin/env python

# TODO: Parsing CLI arguments & Configuration
# TODO: Spotify authorization
# TODO: Cleanup the stuff when ending the program

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

        logging.debug("Trying to spotify authenticate...")

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
        """ run function """

        # Log info
        logging.info("Starting the main loop.")
        
        # Get the server object
        server = self.create_server("localhost", 9999)        

        # After creating the socket, drop privileges
        # functions.drop_privileges()

        # Start listening for connections
        while True:

            try:
                command = server.handle_request()
            except BaseException as e:
                print(e)

            logging.info("The command we got is:" + command)
            print(command)

            self.process_data(command)
# Main
if __name__ == "__main__":

    # Load the configuration

    # Set the level of logging
    logging.basicConfig(level="INFO")

    # Create the object
    mainObj = RaspDaemon("11131855676", "cfa3f1960a626bef1caeb6c2e3338db25f6d8944", "spotify:user:spotify:playlist:37i9dQZF1DX6ziVCJnEm59")

    # Authenticate
    mainObj.authenticate()

    # Run the shit!
    mainObj.run()
