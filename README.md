# IP Indicator

Display your public IP, ISP, and location.

<img src="screenshot.png" width="300" alt="Screenshot">

## Install

**Required:** This plugin requires [dms-common](https://github.com/hthienloc/dms-common) to be installed.

```bash
# 1. Install shared components
git clone https://github.com/hthienloc/dms-common ~/.config/DankMaterialShell/plugins/dms-common

# 2. Install this plugin
dms plugins install ipIndicator
```

Or manually:

```bash
git clone https://github.com/hthienloc/dms-ipIndicator ~/.config/DankMaterialShell/plugins/ipIndicator
```

## Features

- **IP info at a glance** - Country flag, IP address, and ISP details
- **Privacy mode** - Click the eye button in popout header to toggle IP visibility
- **Quick Refresh** - Right-click the bar icon to instantly update connection status
- **Smart VPN Detection** - Automatically detects active VPN/proxy interfaces
- **Latency & Local Details** - Real-time latency monitor and local IP network details


## Usage

| Action | Result |
|--------|--------|
| Left click | Open details popout |
| Right click | Refresh network status |

## Requirements

- `curl` - HTTP requests to ip-api.com

## License

GPL-3.0

## Done

- [x] Smart VPN Detection
- [x] Latency Monitor
- [x] Local IP Details
- [x] Service Redundancy
- [x] IP Change Notifications