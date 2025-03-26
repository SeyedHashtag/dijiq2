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

### One-Click Installation

```bash
bash <(curl -s https://raw.githubusercontent.com/SeyedHashtag/dijiq2/main/install.sh)
```

After installation, use the `dijiq2` command to launch the bot or `dijiq2-config` to edit the configuration.

### Standard Installation

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

## Configuration

Edit the `.env` file and set these variables:

- `TELEGRAM_TOKEN`: Your Telegram bot token from BotFather
- `ADMIN_USERS`: Comma-separated list of Telegram user IDs who can administer the bot
- `VPN_API_URL`: URL of your VPN API server
- `API_KEY`: Authentication key for the VPN API
- `SUB_URL`: URL for subscription links (typically your VPN server address)

## Usage

1. Start a chat with your bot on Telegram
2. Use the "➕ Add User" button to create a new VPN user
3. Follow the prompts to set username, traffic limit, and expiration
4. Share the generated QR code with your user for easy connection

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, feature requests or questions, please open an issue on the GitHub repository.