import "./dms-common"
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "ipIndicator"

    SettingsCard {
        SectionTitle {
            text: I18n.tr("Bar Display")
            icon: "view_day"
        }

        SelectionSetting {
            settingKey: "displayMode"
            label: I18n.tr("Display")
            description: I18n.tr("What to show on the bar.")
            options: [{
                "label": I18n.tr("Country"),
                "value": "country"
            }, {
                "label": I18n.tr("City"),
                "value": "city"
            }, {
                "label": I18n.tr("ISP"),
                "value": "isp"
            }, {
                "label": I18n.tr("IP Address"),
                "value": "ip"
            }, {
                "label": I18n.tr("Country + IP"),
                "value": "country_ip"
            }, {
                "label": I18n.tr("Country + City"),
                "value": "country_city"
            }, {
                "label": I18n.tr("City + IP"),
                "value": "city_ip"
            }, {
                "label": I18n.tr("Icon Only"),
                "value": "icon"
            }]
            defaultValue: "country"
        }

        ToggleSetting {
            settingKey: "useFlagIcon"
            label: I18n.tr("Use Country Flag as Icon")
            description: I18n.tr("Show the country's flag on the bar pill instead of the default globe icon.")
            defaultValue: true
        }

    }

    SettingsCard {
        SectionTitle {
            text: I18n.tr("Popout")
            icon: "call_made"
        }

        ToggleSetting {
            settingKey: "showIPv4"
            label: I18n.tr("Show IPv4")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showIPv6"
            label: I18n.tr("Show IPv6")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showISP"
            label: I18n.tr("Show ISP")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocation"
            label: I18n.tr("Show Location")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalIP"
            label: I18n.tr("Show Local IP")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalGateway"
            label: I18n.tr("Show Local Gateway")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLocalInterface"
            label: I18n.tr("Show Local Interface")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "showLatency"
            label: I18n.tr("Show Latency")
            defaultValue: true
        }

    }

    SettingsCard {
        SectionTitle {
            text: I18n.tr("Behavior")
            icon: "settings"
        }

        SliderSetting {
            settingKey: "refreshInterval"
            label: I18n.tr("Refresh Interval")
            description: I18n.tr("How often to check for IP changes.")
            minimum: 1
            maximum: 60
            unit: I18n.tr("min")
            defaultValue: 30
        }

        ToggleSetting {
            settingKey: "notifyOnIPChange"
            label: I18n.tr("IP / ISP Change Notifications")
            description: I18n.tr("Show a desktop notification when your public IP address or ISP changes.")
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "privacyDefault"
            label: I18n.tr("Default to Privacy Mode")
            description: I18n.tr("Start the plugin with public IP details hidden by default.")
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "showHints"
            label: I18n.tr("Show Hints")
            description: I18n.tr("Display helpful usage tips and shortcuts at the bottom of the popout.")
            defaultValue: true
        }

    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-ipIndicator"
    }

}
