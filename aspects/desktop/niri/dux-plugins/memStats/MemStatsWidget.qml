// Memory tile in the control center (replaces the old memUsage bar pill).
//
// Clicking opens the *same* compact ProcessListPopout that the bar widget
// opens (Processes view, sorted by memory) — not the larger four-tab System
// Monitor modal.
import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    Ref {
        service: DgopService
        modules: ["memory"]
        active: true
    }

    readonly property int percent: Math.round(DgopService.memoryUsage)
    readonly property string usedText: (DgopService.usedMemoryMB / 1024).toFixed(1) + " / " + (DgopService.totalMemoryMB / 1024).toFixed(1) + " GB"

    property bool pendingOpen: false
    property real pendingX: 0
    property real pendingY: 0
    property real pendingWidth: 60
    property var pendingScreen: null

    function openProcessList() {
        DgopService.setSortBy("memory");

        const cc = PopoutService.controlCenterPopout;
        const screen = (cc && cc.screen) ? cc.screen : (CompositorService.getFocusedScreen() ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null));
        if (!screen)
            return;

        const anchored = cc && cc.triggerWidth > 0;
        pendingX = anchored ? cc.triggerX : screen.width - 60;
        pendingY = anchored ? cc.triggerY : 0;
        pendingWidth = anchored ? cc.triggerWidth : 60;
        pendingScreen = screen;

        PopoutService.closeControlCenter();

        if (PopoutService.processListPopout) {
            openPending();
            return;
        }
        const loader = PopoutService.processListPopoutLoader;
        if (!loader)
            return;
        pendingOpen = true;
        loader.active = true;
    }

    function openPending() {
        pendingOpen = false;
        PopoutService.openProcessList(pendingX, pendingY, pendingWidth, "right", pendingScreen);
    }

    Connections {
        target: PopoutService.processListPopoutLoader
        function onLoaded() {
            if (root.pendingOpen)
                root.openPending();
        }
    }

    ccWidgetIcon: "developer_board"
    ccWidgetPrimaryText: "RAM " + root.percent + "%"
    ccWidgetSecondaryText: root.usedText
    ccWidgetIsActive: root.percent >= 90
    onCcWidgetToggled: root.openProcessList()
}
