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
    }

    SettingsCard {
        SectionTitle { text: "Popout" }

        ToggleSetting {
            settingKey: "showIP"
            label: "Show IP"
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
    }

    SettingsCard {
        SectionTitle { text: "Behavior" }

        SliderSetting {
            settingKey: "refreshInterval"
            label: "Refresh Interval"
            description: "How often to check for IP changes."
            minimum: 5
            maximum: 120
            unit: "min"
            defaultValue: 30
        }

        ToggleSetting {
            settingKey: "notifyOnIPChange"
            label: "IP Change Notifications"
            description: "Show a desktop notification when your public IP or ISP changes."
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