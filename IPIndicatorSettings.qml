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

    LocalI18n {
        id: localI18n
        baseUrl: Qt.resolvedUrl(".")
    }

    PluginHeader {
        title: localI18n.tr("IP Indicator Settings")
    }

    SettingsCard {
        SectionTitle { text: localI18n.tr("Bar Display") }

        SelectionSetting {
            settingKey: "displayMode"
            label: localI18n.tr("Display")
            description: localI18n.tr("What to show on the bar.")
            options: [
                { label: localI18n.tr("Country"), value: "country" },
                { label: localI18n.tr("City"), value: "city" },
                { label: localI18n.tr("ISP"), value: "isp" },
                { label: localI18n.tr("IP Address"), value: "ip" },
                { label: localI18n.tr("Country + IP"), value: "country_ip" },
                { label: localI18n.tr("Country + City"), value: "country_city" },
                { label: localI18n.tr("City + IP"), value: "city_ip" },
                { label: localI18n.tr("Icon Only"), value: "icon" }
            ]
            defaultValue: "country"
        }

        ToggleSetting {
            settingKey: "useFlagIcon"
            label: localI18n.tr("Use Country Flag as Icon")
            description: localI18n.tr("Show the country's flag on the bar pill instead of the default globe icon.")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { text: localI18n.tr("Popout") }

        ToggleSetting {
            settingKey: "showIP"
            label: localI18n.tr("Show Public IP")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showISP"
            label: localI18n.tr("Show ISP")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocation"
            label: localI18n.tr("Show Location")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalIP"
            label: localI18n.tr("Show Local IP")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalGateway"
            label: localI18n.tr("Show Local Gateway")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalInterface"
            label: localI18n.tr("Show Local Interface")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLatency"
            label: localI18n.tr("Show Latency")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { text: localI18n.tr("Behavior") }

        SliderSetting {
            settingKey: "refreshInterval"
            label: localI18n.tr("Refresh Interval")
            description: localI18n.tr("How often to check for IP changes.")
            minimum: 1
            maximum: 60
            unit: "min"
            defaultValue: 30
        }

        ToggleSetting {
            settingKey: "notifyOnIPChange"
            label: localI18n.tr("IP / ISP Change Notifications")
            description: localI18n.tr("Show a desktop notification when your public IP address or ISP changes.")
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "privacyDefault"
            label: localI18n.tr("Default to Privacy Mode")
            description: localI18n.tr("Start the plugin with public IP details hidden by default.")
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "showHints"
            label: localI18n.tr("Show Hints")
            description: localI18n.tr("Display helpful usage tips and shortcuts at the bottom of the popout.")
            defaultValue: true
        }
    }
}