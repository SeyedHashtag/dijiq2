# Dijiq2 - VPN User Management Bot

A Telegram bot for managing VPN users through an API interface. This bot allows VPN service administrators to easily add, manage and monitor users from a convenient Telegram interface.

## Features

- Add new VPN users with customizable traffic limits and expiration dates
- Automatic QR code generation for easy connection
- User-friendly Telegram interface with button controls
- Secure API integration with your VPN service
- Easy deployment with installation script

## Requirements

- Ubuntu 22.04+ or Debian 11+
- Python 3.6 or higher
- Root access on your server
- Telegram Bot Token

## Installation

### Quick Installation

1. SSH into your server
2. Clone the repository:
   ```
   git clone https://github.com/SeyedHashtag/dijiq2.git
   cd dijiq2
   ```
3. Run the installation script:
   ```
   chmod +x install.sh
   ./install.sh
   ```
4. Configure the `.env` file with your settings:
   ```
   nano /etc/hysteria/dijiq2/.env
   ```

### Manual Installation

If you prefer to install manually:

1. Install required packages:
   ```
   apt update && apt install -y jq qrencode curl python3 python3-pip python3-venv git bc zip
   ```
2. Clone the repository:
   ```
   git clone https://github.com/SeyedHashtag/dijiq2.git /etc/hysteria/dijiq2
   cd /etc/hysteria/dijiq2
   ```
3. Create virtual environment and install dependencies:
   ```
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
4. Copy and configure environment variables:
   ```
   cp .env.example .env
   nano .env
   ```

## Configuration

Edit the `.env` file and set these variables:

- `TELEGRAM_TOKEN`: Your Telegram bot token from BotFather
- `ADMIN_USERS`: Comma-separated list of Telegram user IDs who can administer the bot
- `VPN_API_URL`: URL of your VPN API server
- `API_KEY`: Authentication key for the VPN API
- `SUB_URL`: URL for subscription links (typically your VPN server address)

## Running the Bot

### Using the runbot.sh script:

```
/etc/hysteria/dijiq2/src/bot/runbot.sh start <API_TOKEN> <ADMIN_USER_IDS>
```

### Manually:

```
cd /etc/hysteria/dijiq2
source venv/bin/activate
python src/bot/tbot.py
```

## Usage

1. Start a chat with your bot on Telegram
2. Use the "➕ Add User" button to create a new VPN user
3. Follow the prompts to set username, traffic limit, and expiration
4. Share the generated QR code with your user for easy connection

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, feature requests or questions, please open an issue on the GitHub repository.