#!/bin/bash
source /etc/hysteria/core/scripts/utils.sh
define_colors

update_env_file() {
    local api_token=$1
    local admin_user_ids=$2
    local env_file="/etc/hysteria/core/scripts/telegrambot/.env"

    # Save existing Cryptomus credentials if they exist
    local merchant_id=""
    local api_key=""
    if [ -f "$env_file" ]; then
        merchant_id=$(grep CRYPTOMUS_MERCHANT_ID "$env_file" | cut -d '=' -f2)
        api_key=$(grep CRYPTOMUS_API_KEY "$env_file" | cut -d '=' -f2)
    fi

    # Create new .env file
    cat <<EOL > "$env_file"
API_TOKEN=$api_token
ADMIN_USER_IDS=[$admin_user_ids]
EOL

    # Add back Cryptomus credentials if they existed
    if [ ! -z "$merchant_id" ]; then
        echo "CRYPTOMUS_MERCHANT_ID=$merchant_id" >> "$env_file"
    fi
    if [ ! -z "$api_key" ]; then
        echo "CRYPTOMUS_API_KEY=$api_key" >> "$env_file"
    fi
}

create_service_file() {
    cat <<EOL > /etc/systemd/system/hysteria-bot.service
[Unit]
Description=Hysteria Telegram Bot
After=network.target

[Service]
ExecStart=/bin/bash -c 'source /etc/hysteria/hysteria2_venv/bin/activate && /etc/hysteria/hysteria2_venv/bin/python /etc/hysteria/core/scripts/telegrambot/tbot.py'
WorkingDirectory=/etc/hysteria/core/scripts/telegrambot
Restart=always

[Install]
WantedBy=multi-user.target
EOL
}

start_service() {
    local api_token=$1
    local admin_user_ids=$2

    if systemctl is-active --quiet hysteria-bot.service; then
        echo "The hysteria-bot.service is already running."
        return
    fi

    update_env_file "$api_token" "$admin_user_ids"
    create_service_file

    systemctl daemon-reload
    systemctl enable hysteria-bot.service > /dev/null 2>&1
    systemctl start hysteria-bot.service > /dev/null 2>&1

    if systemctl is-active --quiet hysteria-bot.service; then
        echo -e "${green}Hysteria bot setup completed. The service is now running. ${NC}"
        echo -e "\n\n"
    else
        echo "Hysteria bot setup completed. The service failed to start."
    fi
}

stop_service() {
    systemctl stop hysteria-bot.service > /dev/null 2>&1
    systemctl disable hysteria-bot.service > /dev/null 2>&1

    rm -f /etc/hysteria/core/scripts/telegrambot/.env
    echo -e "\n"

    echo "Hysteria bot service stopped and disabled. .env file removed."
}

case "$1" in
    start)
        start_service "$2" "$3"
        ;;
    stop)
        stop_service
        ;;
    *)
        echo "Usage: $0 {start|stop} <API_TOKEN> <ADMIN_USER_IDS>"
        exit 1
        ;;
esac

define_colors
