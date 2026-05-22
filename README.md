# IP Indicator

Display your public IP, ISP, and location.

<img src="screenshot.png" width="300" alt="Screenshot">

## Install

```bash
# Clone the plugin (includes all dependencies)
git clone https://github.com/hthienloc/dms-ipIndicator ~/.config/DankMaterialShell/plugins/ipIndicator

# Or via the plugin manager
dms plugins install ipIndicator
```

## Features

- **IP info at a glance** - Country flag, IP address, ISP
- **Privacy mode** - Right-click to hide/show IP
- **Auto-refresh** - Fetch on startup
- **Smart VPN Detection** - Automatically detects active VPN/proxy interfaces (tun, tap, wg, ppp)
- **Latency Monitor** - Integrated ping tool to measure real-time latency to DNS servers
- **Local IP Details** - Local IP, gateway, and interface name in the popout
- **Service Redundancy** - Failover across 3 IP geolocation providers (ip-api.com, ipinfo.io, ifconfig.me)
- **IP Change Notifications** - Optional desktop notifications when your IP or ISP changes

## Usage

| Action | Result |
|--------|--------|
| Left click | Open details popout |
| Right click | Toggle privacy mode |

## Requirements

- `curl` - HTTP requests to IP geolocation providers

## License

GPL-3.0

## Done

- [x] Smart VPN Detection
- [x] Latency Monitor
- [x] Local IP Details
- [x] Service Redundancy
- [x] IP Change Notifications