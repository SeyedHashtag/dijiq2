#!/usr/bin/env python3
"""
Wrapper script for the Telegram bot that handles exceptions and logging
"""
import os
import sys
import logging
import traceback
from dotenv import load_dotenv

# Add project root to Python path
sys.path.insert(0, '/etc/dijiq2')

def setup_logging():
    """Configure logging to file and console"""
    os.makedirs('/var/log/dijiq2', exist_ok=True)
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    
    # Console handler
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console_format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    console.setFormatter(console_format)
    
    # File handler
    file_handler = logging.FileHandler('/var/log/dijiq2/bot.log')
    file_handler.setLevel(logging.INFO)
    file_format = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(file_format)
    
    # Add handlers
    root_logger.addHandler(console)
    root_logger.addHandler(file_handler)
    
    # Create logger for this script
    logger = logging.getLogger('wrapper')
    
    return logger

def check_environment():
    """Check if all required environment variables are set"""
    logger = logging.getLogger('wrapper')
    load_dotenv()
    
    required_vars = [
        'TELEGRAM_TOKEN',
        'ADMIN_USER_IDS',  # Changed back to ADMIN_USER_IDS to match command.py
        'VPN_API_URL',
        'API_KEY',
        'SUB_URL'
    ]
    
    missing = []
    for var in required_vars:
        if not os.getenv(var):
            missing.append(var)
    
    if missing:
        logger.error(f"Missing required environment variables: {', '.join(missing)}")
        logger.error("Please edit the .env file using the dijiq2-config command")
        return False
    
    return True

def run_bot():
    """Import and run the bot safely"""
    logger = logging.getLogger('wrapper')
    
    try:
        logger.info("Starting Dijiq2 bot...")
        
        # Set current directory to the bot directory so imports work correctly
        os.chdir('/etc/dijiq2/src/bot')
        
        # Import the bot module only after environment check
        import tbot
        
        # The bot should start polling in the tbot module
        
    except Exception as e:
        logger.error(f"Failed to start bot: {str(e)}")
        logger.error(traceback.format_exc())
        return False
    
    return True

if __name__ == "__main__":
    logger = setup_logging()
    
    try:
        logger.info("Initializing Dijiq2 bot wrapper...")
        
        if not check_environment():
            logger.error("Environment check failed. Bot not started.")
            sys.exit(1)
        
        if not run_bot():
            logger.error("Bot execution failed.")
            sys.exit(1)
            
        logger.info("Bot initialization completed successfully.")
        
    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}")
        logger.error(traceback.format_exc())
        sys.exit(1)
