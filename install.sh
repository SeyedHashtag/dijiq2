#!/bin/bash

check_os_version() {
    local os_name os_version

    if [ -f /etc/os-release ]; then
        os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
        os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        echo "Unsupported OS or unable to determine OS version."
        exit 1
    fi

    if ! command -v bc &> /dev/null; then
        apt update && apt install -y bc
    fi

    if [[ "$os_name" == "ubuntu" && $(echo "$os_version >= 22" | bc) -eq 1 ]] ||
       [[ "$os_name" == "debian" && $(echo "$os_version >= 11" | bc) -eq 1 ]]; then
        return 0
    else
        echo "This script is only supported on Ubuntu 22+ or Debian 11+."
        exit 1
    fi
}

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

check_os_version

# Define required packages
REQUIRED_PACKAGES=("jq" "qrencode" "curl" "python3" "python3-pip" "python3-venv" "git" "bc" "zip")
MISSING_PACKAGES=()
heavy_checkmark=$(printf "\xE2\x9C\x85")

# Check for missing packages
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! command -v "$package" &> /dev/null; then
        MISSING_PACKAGES+=("$package")
    else
        echo "Install $package $heavy_checkmark"
    fi
done

# Install missing packages
if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "The following packages are missing and will be installed: ${MISSING_PACKAGES[@]}"
    apt update -qq && apt upgrade -y -qq
    for package in "${MISSING_PACKAGES[@]}"; do
        apt install -y -qq "$package" &> /dev/null && echo "Install $package $heavy_checkmark"
    done
else
    echo "All required packages are already installed."
fi

# Set installation directory
INSTALL_DIR="/etc/hysteria/dijiq2"
mkdir -p $INSTALL_DIR

# Clone or update repository
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing repository..."
    cd $INSTALL_DIR
    git pull
else
    echo "Cloning repository..."
    git clone https://github.com/your-username/dijiq2.git $INSTALL_DIR
fi

# Create and activate Python virtual environment
cd $INSTALL_DIR
python3 -m venv venv
source $INSTALL_DIR/venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt &> /dev/null && echo "Install Python requirements $heavy_checkmark"

# Create .env file if it doesn't exist
if [ ! -f "$INSTALL_DIR/.env" ]; then
    echo "Creating .env file from example..."
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
    echo "Please edit $INSTALL_DIR/.env with your configuration"
fi

# Set permissions
chmod +x $INSTALL_DIR/src/bot/runbot.sh

# Create alias for easy access
if ! grep -q "alias dijiq2='source $INSTALL_DIR/venv/bin/activate && cd $INSTALL_DIR'" ~/.bashrc; then
    echo "alias dijiq2='source $INSTALL_DIR/venv/bin/activate && cd $INSTALL_DIR'" >> ~/.bashrc
    source ~/.bashrc
fi

echo ""
echo "Installation completed! $heavy_checkmark"
echo "To start the bot, run: cd $INSTALL_DIR && source venv/bin/activate && python src/bot/tbot.py"
echo "Or use the runbot.sh script: $INSTALL_DIR/src/bot/runbot.sh start <API_TOKEN> <ADMIN_USER_IDS>"
echo ""
echo "Don't forget to edit the .env file with your configuration!"
