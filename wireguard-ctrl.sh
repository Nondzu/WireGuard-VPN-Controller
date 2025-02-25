#!/bin/bash

# WireGuard VPN Manager Script
# Place this in your ~/.wireguard folder

# Get the real user's home directory when running with sudo
if [ -n "$SUDO_USER" ]; then
  REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  REAL_HOME="$HOME"
fi

DEFAULT_CONFIG_FILE="$REAL_HOME/.wireguard/vpn.conf"
DEFAULT_VPN_NAME="vpn"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Function to check if a package is installed
is_package_installed() {
  dpkg -s "$1" &> /dev/null
  return $?
}

# Function to check and install required packages
check_required_packages() {
  local required_packages=("wireguard" "wireguard-tools")
  local missing_packages=()
  
  echo "Checking for required packages..."
  
  for package in "${required_packages[@]}"; do
    if ! is_package_installed "$package"; then
      missing_packages+=("$package")
    fi
  done
  
  if [ ${#missing_packages[@]} -gt 0 ]; then
    echo "The following required packages are not installed:"
    for package in "${missing_packages[@]}"; do
      echo "  - $package"
    done
    
    read -p "Do you want to install these packages now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Installing missing packages..."
      apt update
      apt install -y "${missing_packages[@]}"
      if [ $? -eq 0 ]; then
        echo "Packages installed successfully."
      else
        echo "Failed to install packages. Please install them manually."
        exit 1
      fi
    else
      echo "Packages are required for WireGuard VPN to function properly."
      echo "Please install them manually and try again."
      exit 1
    fi
  else
    echo "All required packages are installed."
  fi
}

# Function to fix permissions
fix_permissions() {
  local config_file="$1"
  echo "Checking config file permissions..."
  if [ -f "$config_file" ] && [ "$(stat -c %a "$config_file")" != "600" ]; then
    echo "Fixing config file permissions..."
    chmod 600 "$config_file"
    echo "Permissions fixed."
  else
    echo "Permissions are already correct."
  fi
}

# Function to extract VPN name from config file
get_vpn_name() {
  local config_file="$1"
  local base_name=$(basename "$config_file")
  echo "${base_name%.*}"
}

# Function to connect to VPN
connect() {
  local config_file="$1"
  local vpn_name="$2"
  
  echo "Connecting to WireGuard VPN using $config_file..."
  fix_permissions "$config_file"
  wg-quick up "$config_file"
  if [ $? -eq 0 ]; then
    echo "Connected successfully to $vpn_name!"
  else
    echo "Connection failed."
  fi
}

# Function to disconnect from VPN
disconnect() {
  local config_file="$1"
  local vpn_name="$2"
  
  echo "Disconnecting from WireGuard VPN ($vpn_name)..."
  wg-quick down "$config_file"
  if [ $? -eq 0 ]; then
    echo "Disconnected successfully from $vpn_name!"
  else
    echo "Disconnection failed."
  fi
}

# Function to check VPN status
check_status() {
  local vpn_name="$1"
  
  echo "Checking WireGuard VPN status..."
  if wg show 2>/dev/null | grep -q "$vpn_name"; then
    echo "VPN ($vpn_name) is CONNECTED"
    
    # Show VPN interface details
    echo -e "\nVPN interface details:"
    ip addr show "$vpn_name" | grep -E 'inet|state'
    
    echo -e "\nConnection details:"
    wg show
    
    # Show public IP address
    echo -e "\nCurrent public IP address:"
    curl -s https://ipinfo.io/ip || echo "Could not determine public IP"
    
    # Show additional IP information
    echo -e "\nIP location information:"
    curl -s https://ipinfo.io | grep -E 'ip|city|region|country|org' || echo "Could not retrieve IP information"
  else
    echo "VPN ($vpn_name) is DISCONNECTED"
    
    # Show public IP address
    echo -e "\nCurrent public IP address:"
    curl -s https://ipinfo.io/ip || echo "Could not determine public IP"
  fi
}

# Parse arguments
ACTION=""
CONFIG_FILE="$DEFAULT_CONFIG_FILE"

# Process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    connect|up|disconnect|down|status|check)
      ACTION="$1"
      shift
      ;;
    -c|--config)
      if [[ -n "$2" && "$2" != -* ]]; then
        CONFIG_FILE="$2"
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    *)
      # If the argument doesn't start with - and no action is set, assume it's a config file
      if [[ "$1" != -* && -z "$ACTION" ]]; then
        ACTION="$1"
        shift
      elif [[ "$1" != -* && -n "$ACTION" ]]; then
        CONFIG_FILE="$1"
        shift
      else
        echo "Unknown option: $1" >&2
        exit 1
      fi
      ;;
  esac
done

# Main script logic
check_required_packages

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  # Try to find the config file in the current directory
  CURRENT_DIR_CONFIG="./$(basename "$CONFIG_FILE")"
  if [ -f "$CURRENT_DIR_CONFIG" ]; then
    echo "Config file not found at $CONFIG_FILE"
    echo "Using config file from current directory: $CURRENT_DIR_CONFIG"
    CONFIG_FILE="$CURRENT_DIR_CONFIG"
  else
    echo "Error: WireGuard configuration file not found at $CONFIG_FILE"
    echo "Also checked: $CURRENT_DIR_CONFIG"
    exit 1
  fi
fi

# Get VPN name from config file
VPN_NAME=$(get_vpn_name "$CONFIG_FILE")

case "$ACTION" in
  connect|up)
    connect "$CONFIG_FILE" "$VPN_NAME"
    ;;
  disconnect|down)
    disconnect "$CONFIG_FILE" "$VPN_NAME"
    ;;
  status|check)
    check_status "$VPN_NAME"
    ;;
  *)
    echo "WireGuard VPN Manager"
    echo "---------------------"
    echo "Usage: $0 {connect|up|disconnect|down|status|check} [-c|--config CONFIG_FILE]"
    echo "  connect/up        - Connect to the VPN"
    echo "  disconnect/down   - Disconnect from the VPN"
    echo "  status/check      - Check VPN connection status"
    echo ""
    echo "Options:"
    echo "  -c, --config FILE - Specify a configuration file (default: $DEFAULT_CONFIG_FILE)"
    echo ""
    echo "Examples:"
    echo "  $0 connect                     - Connect using default config"
    echo "  $0 up -c ~/.wireguard/work.conf - Connect using specified config"
    echo "  $0 disconnect                  - Disconnect default VPN"
    echo "  $0 status                      - Check VPN status"
    ;;
esac

exit 0
