import qrcode
import io
import os
from telebot import types
from utils.command import *
from utils.common import create_main_markup
from dotenv import load_dotenv
from src.api.api_add_user import VpnApiClient
from src.models.user import VpnUser

# Load environment variables for SUB_URL only (API handles its own credentials)
load_dotenv()
SUB_URL = os.getenv('SUB_URL')

def create_cancel_markup(back_step=None):
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
    if back_step:
        markup.row(types.KeyboardButton("⬅️ Back"))
    markup.row(types.KeyboardButton("❌ Cancel"))
    return markup

@bot.message_handler(func=lambda message: is_admin(message.from_user.id) and message.text == '➕ Add User')
def add_user(message):
    msg = bot.reply_to(message, "Enter username:", reply_markup=create_cancel_markup())
    bot.register_next_step_handler(msg, process_add_user_step1)

def process_add_user_step1(message):
    if message.text == "❌ Cancel":
        bot.reply_to(message, "Process canceled.", reply_markup=create_main_markup())
        return

    # Convert username to lowercase immediately
    username = message.text.strip().lower()
    if username == "":
        bot.reply_to(message, "Username cannot be empty. Please enter a valid username.", reply_markup=create_cancel_markup())
        bot.register_next_step_handler(message, process_add_user_step1)
        return

    # No need to check for existing users as API will handle that
    msg = bot.reply_to(message, "Enter traffic limit (GB):", reply_markup=create_cancel_markup(back_step=process_add_user_step1))
    bot.register_next_step_handler(msg, process_add_user_step2, username)

def process_add_user_step2(message, username):
    if message.text == "❌ Cancel":
        bot.reply_to(message, "Process canceled.", reply_markup=create_main_markup())
        return
    if message.text == "⬅️ Back":
        msg = bot.reply_to(message, "Enter username:", reply_markup=create_cancel_markup())
        bot.register_next_step_handler(msg, process_add_user_step1)
        return

    try:
        traffic_limit = int(message.text.strip())
        msg = bot.reply_to(message, "Enter expiration days:", reply_markup=create_cancel_markup(back_step=process_add_user_step2))
        bot.register_next_step_handler(msg, process_add_user_step3, username, traffic_limit)
    except ValueError:
        bot.reply_to(message, "Invalid traffic limit. Please enter a number:", reply_markup=create_cancel_markup(back_step=process_add_user_step1))
        bot.register_next_step_handler(message, process_add_user_step2, username)

def process_add_user_step3(message, username, traffic_limit):
    if message.text == "❌ Cancel":
        bot.reply_to(message, "Process canceled.", reply_markup=create_main_markup())
        return
    if message.text == "⬅️ Back":
        msg = bot.reply_to(message, "Enter traffic limit (GB):", reply_markup=create_cancel_markup(back_step=process_add_user_step1))
        bot.register_next_step_handler(msg, process_add_user_step2, username)
        return

    try:
        expiration_days = int(message.text.strip())
        
        # Use API client to add user
        bot.send_chat_action(message.chat.id, 'typing')
        bot.reply_to(message, f"Adding user {username}... Please wait.", reply_markup=types.ReplyKeyboardRemove())
        
        try:
            # Initialize API client - no credentials needed, API handles them internally
            api_client = VpnApiClient()
            
            # Create VpnUser object without password (API will generate it)
            # Username is already lowercase from process_add_user_step1
            user = VpnUser(username, traffic_limit, expiration_days)
            
            # Add user through API
            response = api_client.add_user(user)
            
            # Generate subscription URL using SUB_URL from environment
            sub_url = f"https://{SUB_URL.replace('https://', '').replace('http://', '').rstrip('/')}/sub/normal/{username}#Hysteria2"
            
            # Generate QR code for the URL
            qr = qrcode.make(sub_url)
            bio = io.BytesIO()
            qr.save(bio, 'PNG')
            bio.seek(0)
            
            # Create response message
            result_message = f"User {username} added successfully!\n\n"
            result_message += f"Traffic limit: {traffic_limit} GB\n"
            result_message += f"Expiration days: {expiration_days}\n\n"
            result_message += f"`{sub_url}`"
            
            # Send response with QR code
            bot.send_photo(message.chat.id, photo=bio, caption=result_message, parse_mode="Markdown", 
                          reply_markup=create_main_markup())
            
        except Exception as e:
            bot.reply_to(message, f"Error adding user: {str(e)}", reply_markup=create_main_markup())
            
    except ValueError:
        bot.reply_to(message, "Invalid expiration days. Please enter a number:", reply_markup=create_cancel_markup(back_step=process_add_user_step2))
        bot.register_next_step_handler(message, process_add_user_step3, username, traffic_limit)
