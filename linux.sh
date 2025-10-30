#!/bin/sh


install_daemon()
{
    name="$1"
    bin_path="$2"

    if [ -z "$name" ] || [ -z "$bin_path" ]; then
        echo "Usage: install_daemon <name> <bin_path>" >&2
        return 1
    fi

    if [ ! -f "$bin_path" ]; then
        echo "Binary not found: $bin_path" >&2
        return 1
    fi

    target="/usr/local/bin/${name}"
    service="/etc/systemd/system/${name}.service"
    log_file="/var/log/${name}.log"

    echo ""
    echo "Installing daemon: ${name}"
    echo "Source: ${bin_path}"
    echo "Target: ${target}"
    echo ""

    if systemctl list-units --type=service | grep -q "${name}.service"; then
        echo "Stopping existing service..."
        sudo systemctl stop "${name}" 2>/dev/null || true
    fi

    sudo cp "$bin_path" "$target" || return 1
    sudo chmod 755 "$target" || return 1

    sudo mkdir -p "$(dirname "$log_file")"
    sudo touch "$log_file"
    sudo chmod 664 "$log_file"
    sudo chown lp:lp "$log_file"

    echo "Creating service file at: ${service}"
    sudo tee "$service" >/dev/null <<EOF
[Unit]
Description=${name} Service
After=network.target

[Service]
Type=simple
ExecStart=${target}
Restart=always
RestartSec=5
User=lp
Group=lp
WorkingDirectory=/usr/local/bin
StandardOutput=append:${log_file}
StandardError=append:${log_file}
Environment=GOTRACEBACK=all

[Install]
WantedBy=multi-user.target
EOF

    echo ""
    echo "Adjusting lp0 device permissions"
    sudo chmod 660 /dev/usb/lp0

    echo ""
    echo "Enabling and starting service..."
    sudo systemctl daemon-reload || return 1
    sudo systemctl enable "${name}" || return 1
    sudo systemctl restart "${name}" || return 1

    echo ""
    echo "Daemon '${name}' installed and running!"
    echo "Check status: sudo systemctl status ${name}"
    echo "Log: sudo journalctl -u ${name} -f"
}
