#!/bin/bash

# Set environment variables
INSTALL_DIR="/etc/dijiq2"
LOG_DIR="/var/log/dijiq2"

# Make sure log directory exists
mkdir -p $LOG_DIR

# Change to installation directory
cd $INSTALL_DIR

# Activate virtual environment
source $INSTALL_DIR/venv/bin/activate

# Run the wrapper script which handles errors and logging
python $INSTALL_DIR/src/bot/wrapper.py 2>> $LOG_DIR/error.log

# Exit with the exit code from the Python script
exit $?
