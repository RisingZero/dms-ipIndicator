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

- **IP info at a glance** - Country flag, IP address, ISP
- **Privacy mode** - Right-click to hide/show IP
- **Auto-refresh** - Fetch on startup

## Usage

| Action | Result |
|--------|--------|
| Left click | Open details popout |
| Right click | Toggle privacy mode |

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

