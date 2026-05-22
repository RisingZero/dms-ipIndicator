import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "../dms-common"

PluginComponent {
    id: root

    // Public IP state
    property string publicIP: ""
    property string ispName: ""
    property string countryCode: ""
    property string countryName: ""
    property string regionName: ""
    property string cityName: ""
    property string statusMessage: "..."

    // Settings
    property bool privacyMode: (pluginData.privacyDefault || false)
    property bool autoRefresh: (pluginData.autoRefresh ?? true)
    readonly property bool showHints: (pluginData.showHints ?? true)
    readonly property bool showIP: (pluginData.showIP ?? true)
    readonly property bool showISP: (pluginData.showISP ?? true)
    readonly property bool showLocation: (pluginData.showLocation ?? true)
    readonly property string displayMode: (pluginData.displayMode || "country")
    readonly property bool notifyOnIPChange: (pluginData.notifyOnIPChange ?? false)

    // VPN Detection
    property bool vpnActive: false
    property string vpnInterfaceName: ""

    // Latency
    property string latencyMs: ""
    property string latencyError: ""

    // Local Network
    property string localIP: ""
    property string localGateway: ""
    property string localInterface: ""

    // IP change tracking
    property string lastKnownIP: ""

    // Provider list for redundancy
    property var ipProviders: [
        {
            name: "ip-api.com",
            url: "http://ip-api.com/json",
            parser: function(data) {
                return {
                    ip: data.query || "",
                    isp: data.isp || data.org || "",
                    countryCode: (data.countryCode || "").toLowerCase(),
                    country: data.country || "",
                    region: data.regionName || data.region || "",
                    city: data.city || ""
                }
            }
        },
        {
            name: "ipinfo.io",
            url: "https://ipinfo.io/json",
            parser: function(data) {
                return {
                    ip: data.ip || "",
                    isp: data.org || "",
                    countryCode: (data.country || "").toLowerCase(),
                    country: null,
                    region: data.region || "",
                    city: data.city || ""
                }
            }
        },
        {
            name: "ifconfig.me",
            url: "https://ifconfig.me/all.json",
            parser: function(data) {
                return {
                    ip: data.ip_addr || "",
                    isp: "",
                    countryCode: (data.country_code || "").toLowerCase(),
                    country: data.country || "",
                    region: null,
                    city: data.city || ""
                }
            }
        }
    ]

    Component.onCompleted: {
        checkVPN()
        fetchLocalDetails()
        if (autoRefresh) {
            statusMessage = "Loading..."
            fetchIPInfo()
        } else {
            statusMessage = "Click to fetch"
        }
    }

    function checkVPN() {
        Proc.runCommand(
            "check-vpn",
            ["sh", "-c", "ls /sys/class/net | grep -E '^(tun|tap|wg|ppp)' | head -1"],
            function(output, exitCode) {
                if (exitCode === 0 && output.trim() !== "") {
                    vpnActive = true
                    vpnInterfaceName = output.trim()
                } else {
                    vpnActive = false
                    vpnInterfaceName = ""
                }
            },
            3000
        )
    }

    function measureLatency(target) {
        if (!target) target = "8.8.8.8"
        latencyMs = ""
        latencyError = ""
        Proc.runCommand(
            "ping-" + target,
            ["ping", "-c", "1", "-W", "2", target],
            function(output, exitCode) {
                if (exitCode !== 0) {
                    latencyError = "Fail"
                    return
                }
                var match = output.match(/time=([\d\.]+)\s*ms/)
                if (match) {
                    latencyMs = match[1] + " ms"
                } else {
                    latencyError = "N/A"
                }
            },
            5000
        )
    }

    function fetchLocalDetails() {
        Proc.runCommand(
            "local-iface",
            ["sh", "-c", "ip route get 1.1.1.1 | awk '/dev/ {for(i=1;i<=NF;i++) if($i==\"dev\") print $(i+1); exit}'"],
            function(output, exitCode) {
                if (exitCode === 0 && output.trim() !== "") {
                    localInterface = output.trim()
                } else {
                    localInterface = "N/A"
                }
            },
            3000
        )
        Proc.runCommand(
            "local-gw",
            ["sh", "-c", "ip route | awk '/default/ {print $3; exit}'"],
            function(output, exitCode) {
                if (exitCode === 0 && output.trim() !== "") {
                    localGateway = output.trim()
                } else {
                    localGateway = "N/A"
                }
            },
            3000
        )
        Proc.runCommand(
            "local-ip-addr",
            ["sh", "-c", "hostname -I | awk '{print $1}'"],
            function(output, exitCode) {
                if (exitCode === 0 && output.trim() !== "") {
                    localIP = output.trim()
                } else {
                    localIP = "N/A"
                }
            },
            3000
        )
    }

    function fetchIPInfo() {
        lastKnownIP = publicIP
        statusMessage = "Fetching..."
        tryProvider(0)
    }

    function tryProvider(index) {
        if (index >= ipProviders.length) {
            statusMessage = "Error"
            return
        }
        var provider = ipProviders[index]
        Proc.runCommand(
            "fetch-ip-" + index,
            ["curl", "-s", provider.url],
            function(output, exitCode) {
                if (exitCode !== 0 || !output) {
                    tryProvider(index + 1)
                    return
                }
                try {
                    var data = JSON.parse(output)
                    var parsed = provider.parser(data)

                    publicIP = parsed.ip || ""
                    ispName = parsed.isp || ""
                    countryCode = parsed.countryCode || ""
                    if (parsed.country) countryName = parsed.country
                    regionName = parsed.region || ""
                    cityName = parsed.city || ""

                    if (lastKnownIP && lastKnownIP !== "" && publicIP !== lastKnownIP) {
                        if (notifyOnIPChange) {
                            Proc.runCommand(
                                "notify-ip-change",
                                ["notify-send", "IP Indicator", "IP changed from " + lastKnownIP + " to " + publicIP + (ispName ? " (" + ispName + ")" : "")],
                                function() {},
                                5000
                            )
                        }
                    }

                    statusMessage = "OK"
                } catch (e) {
                    tryProvider(index + 1)
                }
            },
            30000
        )
    }

    function togglePrivacy() {
        privacyMode = !privacyMode
    }

    function getDisplayText() {
        if (root.displayMode === "icon") return ""
        if (privacyMode) return "Hidden"
        if (root.publicIP) {
            switch (root.displayMode) {
                case "ip": return root.publicIP;
                case "country_ip": return (countryCode ? countryCode.toUpperCase() + " " : "") + root.publicIP;
                case "city": return cityName || countryCode.toUpperCase();
                case "isp": return ispName || "N/A";
                case "country_city": return (countryCode ? countryCode.toUpperCase() : "") + (cityName ? " - " + cityName : "");
                case "city_ip": return (cityName ? cityName + " " : "") + root.publicIP;
                case "country":
                default:
                    return countryCode ? countryCode.toUpperCase() : root.publicIP;
            }
        }
        return root.statusMessage
    }

    readonly property color pillColor: {
        if (privacyMode) return Theme.warning
        if (vpnActive) return Theme.success
        if (root.publicIP) return Theme.primary
        return Theme.surfaceText
    }

    pillRightClickAction: () => { togglePrivacy() }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: privacyMode ? "visibility_off" : (vpnActive ? "vpn_key" : "public")
                size: Theme.iconSizeSmall
                color: root.pillColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.getDisplayText()
                color: root.pillColor
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
                visible: root.displayMode !== "icon"
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: privacyMode ? "visibility_off" : (vpnActive ? "vpn_key" : "public")
                size: Theme.iconSizeSmall
                color: root.pillColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.getDisplayText()
                color: root.pillColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.displayMode !== "icon"
            }
        }
    }

    popoutContent: Component {
        FocusScope {
            width: parent ? parent.width : 0
            implicitHeight: mainContent.implicitHeight

            PopoutComponent {
                id: mainContent
                width: parent.width
                headerText: "IP Indicator" + (vpnActive ? " (VPN)" : "")
                detailsText: privacyMode ? "Hidden" : root.statusMessage
                showCloseButton: false

                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    // Buttons
                    Row {
                        spacing: Theme.spacingS
                        anchors.horizontalCenter: parent.horizontalCenter

                        DankButton {
                            text: privacyMode ? "Show" : "Hide"
                            iconName: privacyMode ? "visibility" : "visibility_off"
                            backgroundColor: Theme.warning
                            textColor: Theme.onSurface
                            onClicked: togglePrivacy()
                        }

                        DankButton {
                            text: "Refresh"
                            iconName: "refresh"
                            backgroundColor: Theme.primary
                            textColor: Theme.onPrimary
                            onClicked: {
                                checkVPN()
                                fetchLocalDetails()
                                fetchIPInfo()
                            }
                        }
                    }

                    // VPN badge
                    Row {
                        spacing: Theme.spacingS
                        visible: vpnActive
                        anchors.horizontalCenter: parent.horizontalCenter
                        StyledText {
                            text: "VPN: " + vpnInterfaceName
                            color: Theme.success
                            font.pixelSize: Theme.fontSizeMedium
                        }
                    }

                    // IP
                    Column {
                        spacing: Theme.spacingS
                        visible: root.showIP

                        StyledText {
                            text: "IP"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: (privacyMode || !publicIP) ? "----" : publicIP
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }
                    }

                    // ISP
                    Column {
                        spacing: Theme.spacingS
                        visible: root.showISP

                        StyledText {
                            text: "ISP"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: privacyMode ? "----" : (ispName || "N/A")
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }
                    }

                    // Location
                    Column {
                        spacing: Theme.spacingS
                        visible: root.showLocation

                        StyledText {
                            text: "Location"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: privacyMode ? "----" : (countryName ? countryName + (cityName || regionName ? " - " + (cityName || regionName) : "") : "N/A")
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }
                    }

                    // Local IP Details
                    Column {
                        spacing: Theme.spacingS
                        width: parent.width

                        StyledText {
                            text: "Local Network"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        Row {
                            spacing: Theme.spacingS
                            StyledText { text: "IP:"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
                            StyledText { text: localIP; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                        }
                        Row {
                            spacing: Theme.spacingS
                            StyledText { text: "Gateway:"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
                            StyledText { text: localGateway; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                        }
                        Row {
                            spacing: Theme.spacingS
                            StyledText { text: "Interface:"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
                            StyledText { text: localInterface; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                        }
                    }

                    // Latency Monitor
                    Column {
                        spacing: Theme.spacingS
                        width: parent.width

                        StyledText {
                            text: "Latency (8.8.8.8)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        Row {
                            spacing: Theme.spacingS
                            anchors.horizontalCenter: parent.horizontalCenter
                            StyledText {
                                text: (latencyMs || latencyError || "Click Ping")
                                color: (latencyError ? Theme.error : Theme.surfaceText)
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DankButton {
                                text: "Ping"
                                iconName: "network_ping"
                                onClicked: measureLatency("8.8.8.8")
                            }
                        }
                    }

                    HintSection {
                        showHints: root.showHints
                        width: parent.width

                        HintItem {
                            icon: "mouse"
                            text: "Right-click the bar icon to quickly toggle Privacy Mode"
                        }
                        HintItem {
                            icon: "refresh"
                            text: "Click Refresh if your IP address or connection changes"
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 260
    popoutHeight: {
        let h = 180; // Header + Buttons + VPN badge
        if (root.showIP) h += 50;
        if (root.showISP) h += 50;
        if (root.showLocation) h += 50;
        if (root.showHints) h += 60;
        h += 150; // Local Network + Latency
        return h;
    }
}
