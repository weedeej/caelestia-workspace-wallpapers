import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Caelestia.Config

Layouts.RowLayout {
    id: header

    required property var state
    required property var picker
    required property var mediaService
    Layouts.Layout.fillWidth: true
    spacing: Tokens.spacing.small

    Controls.Label {
        visible: header.picker.pickingDefault
        text: "Choose default wallpaper"
        color: header.state.textSurface
        font: Tokens.font.title.small
    }

    Controls.Label {
        visible: !header.picker.pickingDefault
        text: "Choose wallpaper for workspace:"
        color: header.state.textSurface
        font: Tokens.font.title.small
    }

    QQ.Rectangle {
        visible: !header.picker.pickingDefault &&
            header.picker.editingExistingWorkspace
        Layouts.Layout.preferredWidth: 58
        Layouts.Layout.preferredHeight: 32
        radius: Tokens.rounding.small
        color: header.state.surfaceContainerHigh
        border.width: 1
        border.color: header.state.outlineVariant

        Controls.Label {
            anchors.centerIn: parent
            text: header.picker.selectedWorkspace > 0
                ? header.picker.selectedWorkspace.toString() : ""
            color: header.state.primary
            font: Tokens.font.label.medium
        }
    }

    WorkspaceCombo {
        visible: !header.picker.pickingDefault &&
            !header.picker.editingExistingWorkspace
        state: header.state
        picker: header.picker
    }

    QQ.Item { Layouts.Layout.fillWidth: true }

    LinkButton {
        text: "Refresh"
        enabled: !header.picker.videoMatching
        primaryColor: header.state.primary
        disabledTextColor: Qt.alpha(header.state.textSurface, 0.38)
        onClicked: header.mediaService.rescan()
    }

    LinkButton {
        text: "Cancel"
        enabled: !header.picker.videoMatching
        primaryColor: header.state.primary
        disabledTextColor: Qt.alpha(header.state.textSurface, 0.38)
        onClicked: header.picker.close()
    }
}
