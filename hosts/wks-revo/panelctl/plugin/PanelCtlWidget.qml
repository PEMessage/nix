// Monitor pill for the RTK panel on DP-3.
//
// Icon only in the bar: the AUX DDC path is flaky and has no push events, so
// anything displayed permanently would either need polling (racing panelctl
// and burning retries) or go stale. All queries happen when the popout opens
// via PluginComponent.interactionActive.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string powerState: "" // on | off | standby | suspend | unknown
    property bool powerBusy: false
    property bool brightnessKnown: false
    property bool brightnessBusy: false
    property int brightnessPercent: 50

    popoutWidth: 300
    popoutHeight: 0

    readonly property string powerLabel: {
        switch (powerState) {
        case "on":
            return "On";
        case "off":
            return "Off";
        case "standby":
            return "Standby";
        case "suspend":
            return "Suspend";
        case "unknown":
            return "Unknown";
        default:
            return "…";
        }
    }

    onInteractionActiveChanged: {
        if (interactionActive) {
            queryPower();
            queryBrightness();
        }
    }

    function queryPower() {
        powerBusy = true;
        powerRead.running = true;
    }

    function queryBrightness() {
        brightnessBusy = true;
        brightnessRead.running = true;
    }

    function togglePower() {
        powerBusy = true;
        powerToggle.running = true;
    }

    function commitBrightness(percent) {
        brightnessBusy = true;
        brightnessWrite.command = ["panelctl", "brightness", String(Math.round(percent))];
        brightnessWrite.running = true;
    }

    // -- DDC queries (only while the popout is open) -----------------------

    Process {
        id: powerRead
        command: ["panelctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                root.powerState = value.length > 0 ? value.split(/\s+/)[0] : "unknown";
            }
        }
        onExited: (code, status) => {
            if (code !== 0 && root.powerState === "")
                root.powerState = "unknown";
            root.powerBusy = false;
        }
    }

    Process {
        id: powerToggle
        command: ["panelctl", "power", "toggle"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                if (value.startsWith("off")) {
                    root.powerState = "off";
                } else if (value.startsWith("on")) {
                    root.powerState = "on";
                    root.queryBrightness();
                }
            }
        }
        onExited: (code, status) => {
            root.powerBusy = false;
            if (code !== 0)
                root.powerState = "unknown";
        }
    }

    Process {
        id: brightnessRead
        command: ["panelctl", "brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.trim().match(/^(\d+)%/);
                if (match) {
                    root.brightnessPercent = parseInt(match[1]);
                    root.brightnessKnown = true;
                }
            }
        }
        onExited: (code, status) => {
            root.brightnessBusy = false;
        }
    }

    Process {
        id: brightnessWrite
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.trim().match(/^(\d+)%/);
                if (match) {
                    root.brightnessPercent = parseInt(match[1]);
                    root.brightnessKnown = true;
                }
            }
        }
        onExited: (code, status) => {
            root.brightnessBusy = false;
        }
    }

    // -- bar pill: icon only -----------------------------------------------

    horizontalBarPill: Component {
        DIcon {
            name: "monitor"
            size: Theme.barIconSize(root.barThickness, -4)
            color: Theme.widgetIconColor
        }
    }

    verticalBarPill: Component {
        DIcon {
            name: "monitor"
            size: Theme.barIconSize(root.barThickness)
            color: Theme.widgetIconColor
        }
    }

    // -- popout ------------------------------------------------------------

    popoutContent: Component {
        PopoutComponent {
            headerText: "Monitor"
            detailsText: root.powerBusy ? "Querying panel…" : "DP-3 · DDC/CI"

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DIcon {
                        name: "power_settings_new"
                        size: Theme.iconSizeSmall
                        color: root.powerState === "on" ? Theme.primary : Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: I18n.tr("Power")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: root.powerLabel
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DButton {
                    width: parent.width
                    text: root.powerState === "on" ? I18n.tr("Turn off") : I18n.tr("Turn on")
                    iconName: "power_settings_new"
                    enabled: !root.powerBusy
                    onClicked: root.togglePower()
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        DIcon {
                            name: "brightness_6"
                            size: Theme.iconSizeSmall
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("Brightness")
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.brightnessKnown ? root.brightnessPercent + "%" : "…"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    DSlider {
                        id: brightnessSlider
                        width: parent.width
                        minimum: 1
                        maximum: 100
                        showValue: false
                        enabled: root.brightnessKnown && !root.brightnessBusy && root.powerState !== "off"

                        onSliderValueChanged: value => {
                            root.brightnessPercent = Math.round(value);
                        }
                        onSliderDragFinished: value => {
                            root.commitBrightness(value);
                        }

                        Binding on value {
                            value: root.brightnessPercent
                            when: !brightnessSlider.isDragging
                            restoreMode: Binding.RestoreNone
                        }
                    }
                }
            }
        }
    }
}
