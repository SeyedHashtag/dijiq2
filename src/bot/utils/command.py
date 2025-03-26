import telebot
import subprocess
import json
import os
import shlex
from dotenv import load_dotenv
from telebot import types

load_dotenv()

# Fix the environment variable name to match what's in the .env file
API_TOKEN = os.getenv('TELEGRAM_TOKEN')  # Changed from API_TOKEN to TELEGRAM_TOKEN
ADMIN_USER_IDS = json.loads(os.getenv('ADMIN_USER_IDS', '[]'))  # This is already correct
CLI_PATH = '/etc/hysteria/core/cli.py'
BACKUP_DIRECTORY = '/opt/hysbackup'
bot = telebot.TeleBot(API_TOKEN)

def run_cli_command(command):
    try:
        args = shlex.split(command)
        result = subprocess.check_output(args, stderr=subprocess.STDOUT)
        return result.decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        return f'Error: {e.output.decode("utf-8")}'

def is_admin(user_id):
    # Convert user_id to string for comparison since IDs from the .env might be strings
    return str(user_id) in map(str, ADMIN_USER_IDS)
