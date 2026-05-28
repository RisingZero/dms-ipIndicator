import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "../dms-common"

PluginSettings {
    id: root
    pluginId: "ipIndicator"

    PluginHeader {
        title: "IP Indicator Settings"
    }

    SettingsCard {
        SectionTitle { text: "Bar Display" }

        SelectionSetting {
            settingKey: "displayMode"
            label: "Display"
            description: "What to show on the bar."
            options: [
                { label: "Country", value: "country" },
                { label: "City", value: "city" },
                { label: "ISP", value: "isp" },
                { label: "IP Address", value: "ip" },
                { label: "Country + IP", value: "country_ip" },
                { label: "Country + City", value: "country_city" },
                { label: "City + IP", value: "city_ip" },
                { label: "Icon Only", value: "icon" }
            ]
            defaultValue: "country"
        }

        ToggleSetting {
            settingKey: "useFlagIcon"
            label: "Use Country Flag as Icon"
            description: "Show the country's flag on the bar pill instead of the default globe icon."
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { text: "Popout" }

        ToggleSetting {
            settingKey: "showIP"
            label: "Show Public IP"
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showISP"
            label: "Show ISP"
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocation"
            label: "Show Location"
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalIP"
            label: "Show Local IP"
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalGateway"
            label: "Show Local Gateway"
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalInterface"
            label: "Show Local Interface"
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLatency"
            label: "Show Latency"
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { text: "Behavior" }

        SliderSetting {
            settingKey: "refreshInterval"
            label: "Refresh Interval"
            description: "How often to check for IP changes."
            minimum: 1
            maximum: 60
            unit: "min"
            defaultValue: 30
        }

        ToggleSetting {
            settingKey: "notifyOnIPChange"
            label: "IP / ISP Change Notifications"
            description: "Show a desktop notification when your public IP address or ISP changes."
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "privacyDefault"
            label: "Default to Privacy Mode"
            description: "Start the plugin with public IP details hidden by default."
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "showHints"
            label: "Show Hints"
            description: "Display helpful usage tips and shortcuts at the bottom of the popout."
            defaultValue: true
        }
    }
}