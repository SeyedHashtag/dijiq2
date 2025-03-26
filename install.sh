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
    
    # Create log directory
    mkdir -p /var/log/dijiq2
    chmod 755 /var/log/dijiq2
    
    # Create a startup script to handle errors properly
    cat > /etc/dijiq2/start_bot.sh << EOF
#!/bin/bash
cd /etc/dijiq2
source venv/bin/activate
python src/bot/tbot.py 2>> /var/log/dijiq2/error.log >> /var/log/dijiq2/bot.log
EOF

    chmod +x /etc/dijiq2/start_bot.sh
    
    # Create the systemd service file
    cat > /etc/systemd/system/dijiq2.service << EOF
[Unit]
Description=Dijiq2 VPN Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/dijiq2
ExecStart=/etc/dijiq2/start_bot.sh
Restart=always
RestartSec=10
StandardOutput=append:/var/log/dijiq2/bot.log
StandardError=append:/var/log/dijiq2/error.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dijiq2.service
    echo -e "Created systemd service ${GREEN}$CHECKMARK${NC}"
}

# Create executable commands for controlling the bot
create_commands() {
    echo -e "Setting up command-line tools..."
    
    INSTALL_DIR="/etc/dijiq2"
    
    # Create commands for global access
    cat > /usr/local/bin/dijiq2 << EOF
#!/bin/bash
cd $INSTALL_DIR && source venv/bin/activate && python src/bot/tbot.py "\$@"
EOF
    
    cat > /usr/local/bin/dijiq2-config << EOF
#!/bin/bash
nano $INSTALL_DIR/.env
EOF
    
    cat > /usr/local/bin/dijiq2-logs << EOF
#!/bin/bash
if [ -f "/var/log/dijiq2/bot.log" ]; then
    tail -n 50 /var/log/dijiq2/bot.log
else
    echo "Log file not found"
fi
EOF

    cat > /usr/local/bin/dijiq2-errors << EOF
#!/bin/bash
if [ -f "/var/log/dijiq2/error.log" ]; then
    tail -n 50 /var/log/dijiq2/error.log
else
    echo "Error log file not found"
fi
EOF

    cat > /usr/local/bin/dijiq2-debug << EOF
#!/bin/bash
echo "=== Dijiq2 Diagnostic Tool ==="
echo "Checking installation..."
if [ -d "/etc/dijiq2" ]; then
    echo "✅ Installation directory found"
else
    echo "❌ Installation directory missing"
fi

echo "Checking Python environment..."
if [ -d "/etc/dijiq2/venv" ]; then
    echo "✅ Virtual environment found"
else
    echo "❌ Virtual environment missing"
fi

echo "Checking configuration..."
if [ -f "/etc/dijiq2/.env" ]; then
    echo "✅ Configuration file found"
else
    echo "❌ Configuration file missing"
fi

echo "Checking service status..."
systemctl status dijiq2
EOF
    
    # Make all commands executable
    chmod +x /usr/local/bin/dijiq2
    chmod +x /usr/local/bin/dijiq2-config
    chmod +x /usr/local/bin/dijiq2-logs
    chmod +x /usr/local/bin/dijiq2-errors
    chmod +x /usr/local/bin/dijiq2-debug
    
    echo -e "Created command-line tools ${GREEN}$CHECKMARK${NC}"
}

# Set up permissions for scripts and files
setup_permissions() {
    INSTALL_DIR="/etc/dijiq2"
    
    # Make directories readable
    chmod -R 755 $INSTALL_DIR
    
    # Set appropriate permissions for the .env file
    if [ -f "$INSTALL_DIR/.env" ]; then
        chmod 600 "$INSTALL_DIR/.env"  # Only readable by root
    fi
    
    # Make log directory writable
    chmod 755 /var/log/dijiq2
}

# Display completion message
display_completion() {
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo -e "${YELLOW}The bot has been installed as a system service.${NC}"
    echo -e "- ${GREEN}Start${NC}: systemctl start dijiq2"
    echo -e "- ${YELLOW}Status${NC}: systemctl status dijiq2"
    echo -e "- ${RED}Stop${NC}:  systemctl stop dijiq2"
    echo ""
    echo -e "${YELLOW}Available commands:${NC}"
    echo -e "- ${GREEN}dijiq2${NC}: Run the bot manually"
    echo -e "- ${GREEN}dijiq2-config${NC}: Edit configuration"
    echo -e "- ${GREEN}dijiq2-logs${NC}: View bot logs"
    echo -e "- ${GREEN}dijiq2-errors${NC}: View error logs"
    echo -e "- ${GREEN}dijiq2-debug${NC}: Run diagnostics"
    echo ""
    echo -e "${YELLOW}If you encounter issues, check logs with: ${GREEN}dijiq2-errors${NC}"
}

# Main installation process
main() {
    display_logo
    check_root
    check_os_version
    install_dependencies
    setup_dijiq2
    create_service
    create_commands
    setup_permissions
    display_completion
    
    # If this is an update and the service was running, restart it automatically
    if [ "$IS_UPDATE" = true ]; then
        if [ "$SERVICE_WAS_RUNNING" = true ]; then
            echo -e "${YELLOW}Restarting service to apply updates...${NC}"
            systemctl restart dijiq2
            echo -e "${GREEN}Service restarted successfully!${NC}"
        else
            # For updates where the service wasn't running, ask if they want to start it
            read -p "Do you want to start the bot now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                systemctl start dijiq2
                echo -e "${GREEN}Bot started! Check status with: systemctl status dijiq2${NC}"
            fi
        fi
    else
        # For fresh installations, ask if they want to start it
        read -p "Do you want to start the bot now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl start dijiq2
            echo -e "${GREEN}Bot started! Check status with: systemctl status dijiq2${NC}"
        fi
    fi
}

# Execute the installation
main

