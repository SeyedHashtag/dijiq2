#!/bin/bash

# Define colors for better readability
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Log file location
LOG_DIR="/var/log/dijiq2"
LOG_FILE="$LOG_DIR/bot.log"

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

echo -e "${YELLOW}Starting Dijiq2 VPN Bot...${NC}" | tee -a "$LOG_FILE"
echo "$(date): Bot startup initiated" >> "$LOG_FILE"

# Check if we're in the right directory
if [ ! -f "src/bot/tbot.py" ]; then
    echo -e "${RED}Error: Bot script not found. Make sure you're running from the correct directory.${NC}" | tee -a "$LOG_FILE"
    echo "Current directory: $(pwd)" >> "$LOG_FILE"
    exit 1
fi

# Validate .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found. Please run 'dijiq2-config' to set up your configuration.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Ensure virtual environment is activated
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "Activating virtual environment..." >> "$LOG_FILE"
    if [ -d "venv" ]; then
        source venv/bin/activate
    else
        echo -e "${RED}Error: Virtual environment not found.${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Check required Python packages
echo "Checking required Python packages..." >> "$LOG_FILE"
required_packages=("pyTelegramBotAPI" "python-dotenv" "requests" "qrcode" "Pillow")
missing_packages=()

for package in "${required_packages[@]}"; do
    python -c "import pkg_resources; pkg_resources.require('$package')" &>/dev/null || missing_packages+=("$package")
done

if [ ${#missing_packages[@]} -ne 0 ]; then
    echo -e "${YELLOW}Installing missing Python packages: ${missing_packages[@]}${NC}" | tee -a "$LOG_FILE"
    pip install ${missing_packages[@]} >> "$LOG_FILE" 2>&1
fi

# Run the bot with detailed error reporting
echo -e "${GREEN}Starting bot...${NC}" | tee -a "$LOG_FILE"
python src/bot/tbot.py 2>&1 | tee -a "$LOG_FILE"

# Check if the bot crashed
if [ $? -ne 0 ]; then
    echo -e "${RED}Bot crashed. Check logs at $LOG_FILE for more details.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi
