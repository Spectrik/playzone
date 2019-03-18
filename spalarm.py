#!/usr/bin/env python

# CHECK: https://gist.github.com/cpaelzer/fc3abd28f81eda55ffb317bb4091bf48

import raspdaemon
import logging
import os
import sys

# Main
if __name__ == "__main__":

    # Load the configuration

    # Set the level of logging
    logging.basicConfig(level="INFO")

    # Create the object
    mainObj = raspdaemon.RaspDaemon("11131855676", "cfa3f1960a626bef1caeb6c2e3338db25f6d8944", "spotify:user:spotify:playlist:37i9dQZF1DX6ziVCJnEm59")

    # Authenticate
    mainObj.authenticate()
    
    # Run the shit!
    mainObj.run()
