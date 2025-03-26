#!/bin/bash

# Text formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
heavy_checkmark=$(printf "\xE2\x9C\x85")

# Logo display function
display_logo() {
    clear
    echo -e "${GREEN}"
    echo -e "██████╗ ██╗     ██╗██╗ ██████╗ ██████╗ "
    echo -e "██╔══██╗██║     ██║██║██╔═══██╗╚════██╗"
    echo -e "██║  ██║██║     ██║██║██║   ██║ █████╔╝"
    echo -e "██║  ██║██║██   ██║██║██║▄▄ ██║██╔═══╝ "
    echo -e "██████╔╝██║╚█████╔╝██║╚██████╔╝███████╗"
    echo -e "╚═════╝ ╚═╝ ╚════╝ ╚═╝ ╚══▀▀═╝ ╚══════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}VPN User Management Bot - Installation${NC}"
    echo ""
}

check_os_version() {
    local os_name os_version

    echo -e "Checking OS compatibility..."
    
    if [ -f /etc/os-release ]; then
        os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
        os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        echo -e "${RED}Unsupported OS or unable to determine OS version.${NC}"
        exit 1
    fi

    if ! command -v bc &> /dev/null; then
        apt update && apt install -y bc
    fi

    if [[ "$os_name" == "ubuntu" && $(echo "$os_version >= 22" | bc) -eq 1 ]] ||
       [[ "$os_name" == "debian" && $(echo "$os_version >= 11" | bc) -eq 1 ]]; then
        echo -e "${GREEN}OS check passed: $os_name $os_version${NC}"
        return 0
    else
        echo -e "${RED}This script is only supported on Ubuntu 22+ or Debian 11+.${NC}"
        exit 1
    fi
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}This script must be run as root.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Root access confirmed.${NC}"
}

install_dependencies() {
    echo -e "Installing required packages..."
    
    REQUIRED_PACKAGES=("jq" "qrencode" "curl" "python3" "python3-pip" "python3-venv" "git" "bc" "zip")
    MISSING_PACKAGES=()

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            MISSING_PACKAGES+=("$package")
        else
            echo -e "Package $package ${GREEN}$heavy_checkmark${NC}"
        fi
    done

    if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
        echo -e "Installing missing packages: ${YELLOW}${MISSING_PACKAGES[@]}${NC}"
        apt update -qq && apt upgrade -y -qq
        for package in "${MISSING_PACKAGES[@]}"; do
            apt install -y -qq "$package" &> /dev/null && echo -e "Package $package ${GREEN}$heavy_checkmark${NC}"
        done
    else
        echo -e "${GREEN}All required packages are already installed.${NC}"
    fi
}

setup_repository() {
    echo -e "Setting up repository..."
    
    # Set installation directory
    INSTALL_DIR="/etc/hysteria/dijiq2"
    mkdir -p $INSTALL_DIR

    # Check if we're running from the cloned repository or via curl
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "Updating existing repository..."
        cd $INSTALL_DIR
        git pull
    else
        echo -e "Cloning repository..."
        git clone https://github.com/SeyedHashtag/dijiq2.git $INSTALL_DIR
    fi

    cd $INSTALL_DIR
    echo -e "${GREEN}Repository setup complete.${NC}"
}

setup_python_environment() {
    echo -e "Setting up Python environment..."
    
    INSTALL_DIR="/etc/hysteria/dijiq2"
    cd $INSTALL_DIR
    
    # Create virtual environment
    python3 -m venv venv
    source $INSTALL_DIR/venv/bin/activate
    
    # Upgrade pip and install requirements
    pip install --upgrade pip &> /dev/null
    pip install -r requirements.txt && echo -e "${GREEN}Python requirements installed $heavy_checkmark${NC}"
}

setup_configuration() {
    echo -e "Setting up configuration..."
    
    INSTALL_DIR="/etc/hysteria/dijiq2"
    
    # Create .env file if it doesn't exist
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        echo -e "Creating .env file from example..."
        cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
        echo -e "${YELLOW}Please edit $INSTALL_DIR/.env with your configuration${NC}"
    else
        echo -e "${GREEN}.env file already exists.${NC}"
    fi
    
    # Set permissions
    chmod +x $INSTALL_DIR/src/bot/runbot.sh
}

setup_alias() {
    echo -e "Setting up command alias..."
    
    INSTALL_DIR="/etc/hysteria/dijiq2"
    
    # Create alias for easy access
    if ! grep -q "alias dijiq2=" ~/.bashrc; then
        echo "alias dijiq2='cd $INSTALL_DIR && source venv/bin/activate && python src/bot/tbot.py'" >> ~/.bashrc
        echo "alias dijiq2-config='nano $INSTALL_DIR/.env'" >> ~/.bashrc
        
        # Also add to .bash_profile for login shells
        if [ -f ~/.bash_profile ]; then
            echo "alias dijiq2='cd $INSTALL_DIR && source venv/bin/activate && python src/bot/tbot.py'" >> ~/.bash_profile
            echo "alias dijiq2-config='nano $INSTALL_DIR/.env'" >> ~/.bash_profile
        fi
        
        echo -e "${GREEN}Aliases added to your shell configuration.${NC}"
    else
        echo -e "${GREEN}Aliases already exist.${NC}"
    fi
}

display_completion() {
    echo ""
    echo -e "${GREEN}Installation completed! $heavy_checkmark${NC}"
    echo ""
    echo -e "${YELLOW}To configure the bot:${NC}"
    echo -e "  Edit the .env file: ${GREEN}nano /etc/hysteria/dijiq2/.env${NC}"
    echo -e "  Or use the alias: ${GREEN}dijiq2-config${NC}"
    echo ""
    echo -e "${YELLOW}To start the bot:${NC}"
    echo -e "  Use the command: ${GREEN}dijiq2${NC}"
    echo ""
    echo -e "You may need to restart your shell or run ${GREEN}source ~/.bashrc${NC} for the aliases to take effect."
}

main() {
    display_logo
    check_root
    check_os_version
    install_dependencies
    setup_repository
    setup_python_environment
    setup_configuration
    setup_alias
    display_completion
}

main

