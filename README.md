# WireGuard VPN Controller

A simple yet powerful bash script to manage WireGuard VPN connections on Linux systems.

## Features

- Easy connection and disconnection to WireGuard VPNs
- Automatic detection of configuration files
- Detailed status information including VPN IP and location data
- Automatic package dependency checking and installation
- Proper permission handling for configuration files
- Works correctly with sudo

## Requirements

- Linux system with apt package manager (Debian, Ubuntu, etc.)
- Root privileges (sudo)
- WireGuard installed (script can install it if missing)

## Installation

1. Clone this repository or download the script:

```bash
git clone https://github.com/Nondzu/WireGuard-VPN-Controller.git
cd wireguard-vpn-controller
```

2. Make the script executable:

```bash
chmod +x wireguard-ctrl.sh
```

3. Place your WireGuard configuration file(s) in the `~/.wireguard/` directory or in the same directory as the script.

## Usage

The script requires root privileges, so always use it with `sudo`:

```bash
sudo ./wireguard-ctrl.sh COMMAND [OPTIONS]
```

### Commands

- `connect` or `up`: Connect to the VPN
- `disconnect` or `down`: Disconnect from the VPN
- `status` or `check`: Check VPN connection status

### Options

- `-c, --config FILE`: Specify a configuration file (default: `~/.wireguard/vpn.conf`)

### Examples

Connect using the default configuration:
```bash
sudo ./wireguard-ctrl.sh connect
```

Connect using a specific configuration file:
```bash
sudo ./wireguard-ctrl.sh up -c ~/.wireguard/work.conf
```

Disconnect from the VPN:
```bash
sudo ./wireguard-ctrl.sh disconnect
```

Check VPN status:
```bash
sudo ./wireguard-ctrl.sh status
```

## Configuration Files

WireGuard configuration files should be placed in the `~/.wireguard/` directory or in the same directory as the script. The default configuration file is expected to be named `vpn.conf`.

A typical WireGuard configuration file looks like:

```
[Interface]
Address = 10.7.0.1/24
DNS = 1.1.1.1, 1.0.0.1
PrivateKey = YourPrivateKeyHere=

[Peer]
PublicKey = PeerPublicKeyHere=
PresharedKey = PresharedKeyHere=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = server.example.com:51820
PersistentKeepalive = 25
```

## WireGuard Server Installation

This script is designed to manage WireGuard VPN client connections. If you need to set up a WireGuard server, please refer to:

[https://github.com/angristan/wireguard-install](https://github.com/angristan/wireguard-install)

The angristan/wireguard-install repository provides a simple script to set up a WireGuard VPN server on Linux. After setting up your server, you can use the configuration files generated by that script with this client manager.

## Status Information

When checking the status with `sudo ./wireguard-ctrl.sh status`, the script provides:

1. Connection state (connected or disconnected)
2. VPN interface details including IP address
3. WireGuard connection details
4. Current public IP address
5. IP location information (city, region, country, organization)

## Security

- The script automatically fixes permissions on configuration files to ensure they are only readable by root (chmod 600)
- Private keys in configuration files should be kept secure

## Troubleshooting

If you encounter issues:

1. Ensure WireGuard is properly installed
2. Check that your configuration file has the correct format and permissions
3. Verify that you're running the script with sudo
4. Check system logs for more information: `sudo journalctl -xe`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 
