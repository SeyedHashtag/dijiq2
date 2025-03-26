#!/bin/bash

# Set terminal colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color
CHECKMARK="✅"

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

# Check if script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}This script must be run as root.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Root access confirmed.${NC}"
}

# Check OS compatibility
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

    if [[ "$os_name" == "ubuntu" && $(echo "$os_version >= 20" | bc) -eq 1 ]] ||
       [[ "$os_name" == "debian" && $(echo "$os_version >= 10" | bc) -eq 1 ]]; then
        echo -e "${GREEN}OS check passed: $os_name $os_version${NC}"
        return 0
    else
        echo -e "${RED}This script is only supported on Ubuntu 20+ or Debian 10+.${NC}"
        exit 1
    fi
}

# Install required packages
install_dependencies() {
    echo -e "Installing required packages..."
    
    REQUIRED_PACKAGES=("python3" "python3-pip" "python3-venv" "git" "curl" "jq" "qrencode" "bc" "zip")
    MISSING_PACKAGES=()

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            MISSING_PACKAGES+=("$package")
        else
            echo -e "Package $package ${GREEN}$CHECKMARK${NC}"
        fi
    done

    if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
        echo -e "${YELLOW}Installing missing packages: ${MISSING_PACKAGES[@]}${NC}"
        apt update -qq && apt upgrade -y -qq
        for package in "${MISSING_PACKAGES[@]}"; do
            apt install -y -qq "$package" &> /dev/null && echo -e "Installed $package ${GREEN}$CHECKMARK${NC}"
        done
    else
        echo -e "${GREEN}All required packages are already installed.${NC}"
    fi
}

# Set up the Dijiq2 VPN Bot
setup_dijiq2() {
    INSTALL_DIR="/etc/dijiq2"
    IS_UPDATE=false
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Dijiq2 installation found. Updating...${NC}"
        cd "$INSTALL_DIR"
        
        # Check if the service is running before updating
        SERVICE_WAS_RUNNING=false
        if systemctl is-active --quiet dijiq2.service; then
            SERVICE_WAS_RUNNING=true
            echo -e "${YELLOW}Stopping service for update...${NC}"
            systemctl stop dijiq2.service
        fi
        
        # Store current version before update
        PREV_VERSION=""
        if [ -f "VERSION" ]; then
            PREV_VERSION=$(cat VERSION)
        fi
        
        # Perform the update
        git pull
        
        # Set flag to indicate this is an update
        IS_UPDATE=true
        
        # If there's a version file, check if version changed
        if [ -f "VERSION" ]; then
            CURR_VERSION=$(cat VERSION)
            if [ "$PREV_VERSION" != "$CURR_VERSION" ] && [ ! -z "$PREV_VERSION" ]; then
                echo -e "${GREEN}Updated from version $PREV_VERSION to $CURR_VERSION${NC}"
                
                # Display changelog if available
                if [ -f "CHANGELOG.md" ]; then
                    echo -e "${YELLOW}Changelog:${NC}"
                    cat CHANGELOG.md | head -n 20  # Show first 20 lines of changelog
                    echo -e "${YELLOW}...(see full changelog in CHANGELOG.md)${NC}"
                fi
            fi
        fi
    else
        echo -e "${GREEN}Cloning Dijiq2 VPN Bot...${NC}"
        mkdir -p $(dirname "$INSTALL_DIR")
        git clone https://github.com/SeyedHashtag/dijiq2.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
    
    # Create Python virtual environment
    echo -e "${GREEN}Setting up Python environment...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip &> /dev/null
    pip install -r requirements.txt && echo -e "Installed Python requirements ${GREEN}$CHECKMARK${NC}"
    
    # Configure the bot using environment variables
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}Please provide the following credentials for your bot:${NC}"
        
        # Ask for Telegram bot token
        read -p "Enter your Telegram bot token: " telegram_token
        
        # Ask for admin Telegram user ID
        read -p "Enter your Telegram user ID (for admin access): " admin_id
        
        # Ask for VPN API URL
        read -p "Enter your VPN API URL: " api_url
        
        # Ask for API key
        read -p "Enter your VPN API key: " api_key
        
        # Ask for subscription URL
        read -p "Enter your subscription URL (press Enter to use same as API URL): " sub_url
        if [ -z "$sub_url" ]; then
            sub_url=$api_url
        fi
        
        # Create the .env file
        cat > "$INSTALL_DIR/.env" << EOF
# Telegram Bot Token
TELEGRAM_TOKEN=$telegram_token

# Admin User IDs (comma-separated list of Telegram user IDs)
ADMIN_USERS=$admin_id

# VPN server API URL (used for API requests)
VPN_API_URL=$api_url

# VPN server API Key
API_KEY=$api_key

# Subscription URL for generating user links
SUB_URL=$sub_url
EOF
        echo -e "Environment configuration file created ${GREEN}$CHECKMARK${NC}"
    else
        echo -e "Environment configuration file already exists ${GREEN}$CHECKMARK${NC}"
    fi
    
    # Export variables for later use
    export IS_UPDATE SERVICE_WAS_RUNNING
}

# Create a systemd service for auto-start with environment variables
create_service() {
    echo -e "Creating systemd service..."
    
    cat > /etc/systemd/system/dijiq2.service << EOF
[Unit]
Description=Dijiq2 VPN Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/dijiq2
ExecStart=/etc/dijiq2/venv/bin/python /etc/dijiq2/src/bot/tbot.py
Restart=always
RestartSec=10
# Environment variables are loaded from .env file using python-dotenv
StandardError=append:/var/log/dijiq2/error.log
[Install]ment variables are loaded from .env file using python-dotenv
WantedBy=multi-user.target
EOFstall]
WantedBy=multi-user.target
    systemctl daemon-reload
    systemctl enable dijiq2.service
    echo -e "Created systemd service ${GREEN}$CHECKMARK${NC}"
}   mkdir -p /var/log/dijiq2
    chmod 755 /var/log/dijiq2
# Create executable commands for controlling the bot
create_commands() {n-reload
    echo -e "Setting up command-line tools..."
    echo -e "Created systemd service ${GREEN}$CHECKMARK${NC}"
    INSTALL_DIR="/etc/dijiq2"
    
    # Create commands for global accesslling the bot
    cat > /usr/local/bin/dijiq2 << EOF
#!/bin/bash "Setting up command-line tools..."
cd $INSTALL_DIR && source venv/bin/activate && python src/bot/tbot.py "\$@"
EOF INSTALL_DIR="/etc/dijiq2"
    
    cat > /usr/local/bin/dijiq2-config << EOF
#!/bin/bashusr/local/bin/dijiq2 << EOF
nano $INSTALL_DIR/.env
EOF$INSTALL_DIR && source venv/bin/activate && python src/bot/tbot.py "\$@"
    
    cat > /usr/local/bin/dijiq2-logs << EOF
#!/bin/bashnfig << EOF
if [ -f "/var/log/dijiq2/bot.log" ]; then
    tail -n 50 /var/log/dijiq2/bot.log $INSTALL_DIR/.env
else
    echo "Log file not found"   
fi    # Make them executable
EOF
al/bin/dijiq2-config
    cat > /usr/local/bin/dijiq2-debug << EOF
#!/bin/bashecho -e "Created 'dijiq2' and 'dijiq2-config' commands ${GREEN}$CHECKMARK${NC}"
echo "=== Dijiq2 Diagnostic Tool ==="
echo "Checking installation..."
if [ -d "/etc/dijiq2" ]; then
    echo "✅ Installation directory found"permissions() {
elseINSTALL_DIR="/etc/dijiq2"
    echo "❌ Installation directory missing"
fi

echo "Checking Python environment..."mod +x $INSTALL_DIR/src/bot/start_bot.sh
if [ -d "/etc/dijiq2/venv" ]; then   
    echo "✅ Virtual environment found"    # Set appropriate permissions for the .env file
elseenv" ]; then
    echo "❌ Virtual environment missing"chmod 600 "$INSTALL_DIR/.env"  # Only readable by root
fi

echo "Checking configuration..."tory writable
if [ -f "/etc/dijiq2/.env" ]; thenjiq2
    echo "✅ Configuration file found"ar/log/dijiq2
else
    echo "❌ Configuration file missing"
firocess
() {
echo "Checking service status..."
systemctl status dijiq2

echo "Checking logs..."
if [ -f "/var/log/dijiq2/bot.log" ]; then
    echo "=== Last 10 log entries ==="
    tail -n 10 /var/log/dijiq2/bot.log
elsesetup_permissions
    echo "❌ Log file not found"
fimplete!${NC}"
s a system service.${NC}"
echo "=== End of diagnostics ==="
EOF systemctl status dijiq2"
    
    # Make them executable"${YELLOW}You can also run the bot using the 'dijiq2' command.${NC}"
    chmod +x /usr/local/bin/dijiq2
    chmod +x /usr/local/bin/dijiq2-config
    chmod +x /usr/local/bin/dijiq2-logs an update and the service was running, restart it automatically
    chmod +x /usr/local/bin/dijiq2-debug
    true ]; then
    echo -e "Created command-line tools ${GREEN}$CHECKMARK${NC}"
}stemctl restart dijiq2
  echo -e "${GREEN}Service restarted successfully!${NC}"
# Set up permissions for scripts and fileselse
setup_permissions() { if they want to start it
    INSTALL_DIR="/etc/dijiq2"1 -r
    echo
    # Make sure runbot script is executablethen
    if [ -f "$INSTALL_DIR/src/bot/runbot.sh" ]; thenjiq2
        chmod +x "$INSTALL_DIR/src/bot/runbot.sh"NC}"
    fi  fi
      fi
    # Set appropriate permissions for the .env file   else
    if [ -f "$INSTALL_DIR/.env" ]; then        # For fresh installations, ask if they want to start it
        chmod 600 "$INSTALL_DIR/.env"  # Only readable by rootnt to start the bot now? (y/n) " -n 1 -r
    fi    echo
}        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl start dijiq2
























































main# Execute the installation}    fi        fi            echo -e "${GREEN}Bot started! Check status with: systemctl status dijiq2${NC}"            systemctl start dijiq2        if [[ $REPLY =~ ^[Yy]$ ]]; then        echo        read -p "Do you want to start the bot now? (y/n) " -n 1 -r        # For fresh installations, ask if they want to start it    else        fi            fi                echo -e "${GREEN}Bot started! Check status with: systemctl status dijiq2${NC}"                systemctl start dijiq2            if [[ $REPLY =~ ^[Yy]$ ]]; then            echo            read -p "Do you want to start the bot now? (y/n) " -n 1 -r            # For updates where the service wasn't running, ask if they want to start it        else            echo -e "${GREEN}Service restarted successfully!${NC}"            systemctl restart dijiq2            echo -e "${YELLOW}Restarting service to apply updates...${NC}"        if [ "$SERVICE_WAS_RUNNING" = true ]; then    if [ "$IS_UPDATE" = true ]; then    # If this is an update and the service was running, restart it automatically        echo -e "${YELLOW}For troubleshooting, use the 'dijiq2-debug' command.${NC}"    echo -e "${YELLOW}To view logs, use the 'dijiq2-logs' command.${NC}"    echo -e "${YELLOW}To edit configuration, use the 'dijiq2-config' command.${NC}"    echo -e "${YELLOW}You can also run the bot using the 'dijiq2' command.${NC}"    echo -e "- ${RED}Stop${NC}:  systemctl stop dijiq2"    echo -e "- ${YELLOW}Status${NC}: systemctl status dijiq2"    echo -e "- ${GREEN}Start${NC}: systemctl start dijiq2"    echo -e "${YELLOW}The bot has been installed as a system service.${NC}"    echo -e "${GREEN}Installation complete!${NC}"    echo ""display_completion() {}    display_completion        setup_permissions    create_commands    create_service    setup_dijiq2    install_dependencies    check_os_version    check_root    display_logomain() {# Main installation process            echo -e "${GREEN}Bot started! Check status with: systemctl status dijiq2${NC}"
        fi
    fi
}

# Execute the installation
main

