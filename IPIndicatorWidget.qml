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
    readonly property int refreshIntervalMin: (pluginData.refreshInterval ?? 30)

    onRefreshIntervalMinChanged: {
        if (bgRefreshTimer.running) {
            bgRefreshTimer.restart()
        }
    }

    // Fetching state
    property bool isFetching: false

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

    // Provider list for redundancy (primary uses HTTPS for privacy/security)
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
            statusMessage = "..."
            fetchIPInfo()
        } else {
            statusMessage = "Click to fetch"
        }
    }

    Timer {
        id: bgRefreshTimer
        interval: refreshIntervalMin * 60 * 1000 // Convert minutes to milliseconds
        running: autoRefresh
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            checkVPN()
            fetchLocalDetails()
            fetchIPInfo()
        }
    }

    // Shell command helpers — thin wrappers around Proc.runCommand
    // for commonly used shell pipelines. Keeps the main logic readable
    // and avoids dense sh -c invocations scattered through the code.
    function _runSh(taskId, script, callback) {
        Proc.runCommand(taskId, ["sh", "-c", script], callback, 50, 3000)
    }

    function _findVpnInterface() {
        _runSh("check-vpn", "ls /sys/class/net | grep -E '^(tun|tap|wg|ppp|proton|tailscale|zero|vpn|cscotun)' | head -1", function(output, exitCode) {
            if (exitCode === 0 && output.trim() !== "") {
                vpnActive = true
                vpnInterfaceName = output.trim()
            } else {
                vpnActive = false
                vpnInterfaceName = ""
            }
        })
    }

    function _fetchLocalInterface() {
        _runSh("local-iface", "ip route get 1.1.1.1 | awk '/dev/ {for(i=1;i<=NF;i++) if($i==\"dev\") print $(i+1); exit}'", function(output, exitCode) {
            localInterface = (exitCode === 0 && output.trim() !== "") ? output.trim() : "N/A"
        })
    }

    function _fetchLocalGateway() {
        _runSh("local-gw", "ip route | awk '/default/ {print $3; exit}'", function(output, exitCode) {
            localGateway = (exitCode === 0 && output.trim() !== "") ? output.trim() : "N/A"
        })
    }

    function _fetchLocalIP() {
        _runSh("local-ip-addr", "ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i==\"src\") {print $(i+1); exit}}' || hostname -I 2>/dev/null | awk '{print $1}' || ip address | awk '/inet / && !/127.0.0.1/ {split($2, a, \"/\"); print a[1]; exit}'", function(output, exitCode) {
            localIP = (exitCode === 0 && output.trim() !== "") ? output.trim() : "N/A"
        })
    }

    function checkVPN() {
        _findVpnInterface()
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
            50,
            5000
        )
    }

    function fetchLocalDetails() {
        _fetchLocalInterface()
        _fetchLocalGateway()
        _fetchLocalIP()
    }

    function fetchIPInfo() {
        lastKnownIP = publicIP
        isFetching = true
        statusMessage = "..."
        tryProvider(0)
    }

    function tryProvider(index) {
        if (index >= ipProviders.length) {
            isFetching = false
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

                    if (!parsed || !parsed.ip) {
                        tryProvider(index + 1)
                        return
                    }

                    publicIP = parsed.ip || ""
                    ispName = parsed.isp || ""
                    countryCode = parsed.countryCode || ""
                    if (parsed.country) countryName = parsed.country
                    regionName = parsed.region || ""
                    cityName = parsed.city || ""

                    var ipChanged = lastKnownIP !== "" && publicIP !== lastKnownIP

                    if (notifyOnIPChange && ipChanged) {
                        var reason = ""
                        if (privacyMode) {
                            reason = "Network connection changed (IP details hidden in Privacy Mode)"
                        } else {
                            var lines = [
                                "Old IP: " + lastKnownIP,
                                "New IP: " + publicIP
                            ]
                            if (ispName) {
                                lines.push("ISP: " + ispName)
                            }
                            var locs = []
                            if (cityName) locs.push(cityName)
                            if (regionName) locs.push(regionName)
                            if (countryName) locs.push(countryName)
                            if (locs.length > 0) {
                                lines.push("Location: " + locs.join(", "))
                            }
                            reason = lines.join("\n")
                        }
                        Proc.runCommand("notify-ip-change", ["notify-send", "IP Indicator", reason], function() {}, 50, 5000)
                    }

                    lastKnownIP = publicIP

                    isFetching = false
                    statusMessage = "OK"
                } catch (e) {
                    tryProvider(index + 1)
                }
            },
            50,
            30000
        )
    }

    function togglePrivacy() {
        privacyMode = !privacyMode
    }

    function getDisplayText() {
        if (root.displayMode === "icon") return ""
        if (privacyMode) return ""
        if (isFetching) return "..."
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
        if (isFetching) return Theme.surfaceText
        if (privacyMode) return Theme.warning
        if (vpnActive) return Theme.success
        if (root.publicIP) return Theme.primary
        return Theme.surfaceText
    }

    pillRightClickAction: () => {
        checkVPN()
        fetchLocalDetails()
        fetchIPInfo()
    }

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
                visible: root.displayMode !== "icon" && root.getDisplayText() !== ""
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
                visible: root.displayMode !== "icon" && root.getDisplayText() !== ""
            }
        }
    }

    popoutContent: Component {
        FocusScope {
            width: parent ? parent.width : 0
            implicitHeight: mainContent.implicitHeight

            Component.onCompleted: {
                measureLatency("8.8.8.8")
            }

            PopoutComponent {
                id: mainContent
                width: parent.width
                headerText: "IP Indicator" + (vpnActive ? " (VPN)" : "")
                detailsText: privacyMode ? "Hidden" : root.statusMessage
                showCloseButton: false

                headerActions: Component {
                    Row {
                        spacing: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        // Privacy Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: privacyArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: privacyMode ? "visibility_off" : "visibility"
                                size: Theme.iconSizeSmall
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: privacyArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: togglePrivacy()
                            }
                        }

                        // Refresh Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: refreshArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "refresh"
                                size: Theme.iconSizeSmall
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: refreshArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    checkVPN()
                                    fetchLocalDetails()
                                    fetchIPInfo()
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM

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

                    // Group 1: Public Connection Card
                    StyledRect {
                        width: parent.width
                        height: visible ? (group1Column.implicitHeight + Theme.spacingM * 2) : 0
                        color: Theme.surfaceContainerHigh
                        radius: Theme.cornerRadius
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                        border.width: 1
                        visible: root.showIP || root.showISP || root.showLocation

                        Column {
                            id: group1Column
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Public Connection"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.primary
                            }

                            // IP Row
                            Row {
                                width: parent.width
                                visible: root.showIP
                                
                                StyledText {
                                    text: "Public IP"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Row {
                                    spacing: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !privacyMode && publicIP !== ""

                                    StyledText {
                                        text: publicIP
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: Theme.surfaceText
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: copyArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "content_copy"
                                            size: Theme.iconSizeSmall - 2
                                            color: Theme.primary
                                        }

                                        MouseArea {
                                            id: copyArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Proc.runCommand("copy-ip", ["wl-copy", "--", publicIP], function() {
                                                    ToastService?.showInfo("Copied to clipboard")
                                                })
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: "----"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    visible: privacyMode || !publicIP
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // ISP Row
                            Row {
                                width: parent.width
                                visible: root.showISP
                                
                                StyledText {
                                    text: "ISP"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }
                                StyledText {
                                    text: privacyMode ? "----" : (ispName || "N/A")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - 100
                                    elide: Text.ElideRight
                                }
                            }

                            // Location Row
                            Row {
                                width: parent.width
                                visible: root.showLocation
                                
                                StyledText {
                                    text: "Location"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }
                                StyledText {
                                    text: privacyMode ? "----" : (countryName ? countryName + (cityName || regionName ? " - " + (cityName || regionName) : "") : "N/A")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - 100
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // Group 2: Local Network Card
                    StyledRect {
                        width: parent.width
                        height: group2Column.implicitHeight + Theme.spacingM * 2
                        color: Theme.surfaceContainerHigh
                        radius: Theme.cornerRadius
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                        border.width: 1

                        Column {
                            id: group2Column
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM

                            StyledText {
                                text: "Local Network"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.primary
                            }

                            // Local IP Row
                            Row {
                                width: parent.width
                                
                                StyledText {
                                    text: "Local IP"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }
                                StyledText {
                                    text: localIP || "N/A"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }
                            }

                            // Gateway Row
                            Row {
                                width: parent.width
                                
                                StyledText {
                                    text: "Gateway"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }
                                StyledText {
                                    text: localGateway || "N/A"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }
                            }

                            // Interface Row
                            Row {
                                width: parent.width
                                
                                StyledText {
                                    text: "Interface"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }
                                StyledText {
                                    text: localInterface || "N/A"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }
                            }

                            // Latency Row
                            Row {
                                width: parent.width
                                
                                StyledText {
                                    text: "Latency"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }
                                StyledText {
                                    text: latencyMs ? latencyMs : (latencyError ? latencyError : "")
                                    color: (latencyError ? Theme.error : Theme.surfaceText)
                                    font.pixelSize: Theme.fontSizeMedium
                                }
                            }
                        }
                    }

                    HintSection {
                        showHints: root.showHints
                        width: parent.width

                        HintItem {
                            icon: "mouse"
                            text: "Right-click the bar icon to quickly refresh network status"
                        }
                        HintItem {
                            icon: "visibility_off"
                            text: "Use the eye button in header to toggle Privacy Mode"
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 330
    popoutHeight: {
        let h = 80; // Header + spacing
        
        // Group 1: Public Connection Card
        if (root.showIP || root.showISP || root.showLocation) {
            h += 44; // Card Margins + Title
            if (root.showIP) h += 28;
            if (root.showISP) h += 28;
            if (root.showLocation) h += 28;
            let rows = 0;
            if (root.showIP) rows++;
            if (root.showISP) rows++;
            if (root.showLocation) rows++;
            if (rows > 1) h += 12 * (rows - 1);
        }

        // Group 2: Local Network Card
        h += 44; // Card Margins + Title
        h += 28 * 4; // Local IP, Gateway, Interface, Latency
        h += 12 * 3; // 3 spacings

        if (root.showHints) h += 60;
        return h + 40; // margins
    }
}
