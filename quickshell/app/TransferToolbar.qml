import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Dialogs as Dialogs
import QtQuick.Layouts as Layouts
import Caelestia.Config

Layouts.RowLayout {
    id: toolbar

    required property var state
    required property var configService
    required property var popupParent
    Layouts.Layout.fillWidth: true
    spacing: Tokens.spacing.small

    function openExportJsonDialog() {
        const path = state.configPath
        const folder = path.slice(0, path.lastIndexOf("/"))
        exportJsonDialog.currentFolder = toolbar.state.fileUrl(folder)
        exportJsonDialog.currentFile = toolbar.state.fileUrl(path)
        exportJsonDialog.selectedFile = toolbar.state.fileUrl(path)
        exportJsonDialog.open()
    }

    Dialogs.FileDialog {
        id: importJsonDialog
        title: "Import workspace wallpaper config"
        fileMode: Dialogs.FileDialog.OpenFile
        currentFolder: toolbar.state.fileUrl(toolbar.state.home)
        nameFilters: ["JSON config (*.json)"]
        onAccepted: toolbar.configService.runTransfer("import-json", selectedFile)
    }

    Dialogs.FileDialog {
        id: importZipDialog
        title: "Import workspace wallpaper bundle"
        fileMode: Dialogs.FileDialog.OpenFile
        currentFolder: toolbar.state.fileUrl(toolbar.state.home)
        nameFilters: ["ZIP bundle (*.zip)"]
        onAccepted: toolbar.configService.runTransfer("import-zip", selectedFile)
    }

    Dialogs.FileDialog {
        id: exportJsonDialog
        title: "Export workspace wallpaper config"
        fileMode: Dialogs.FileDialog.SaveFile
        currentFolder: toolbar.state.fileUrl(
            toolbar.state.configPath.slice(
                0, toolbar.state.configPath.lastIndexOf("/")
            )
        )
        currentFile: toolbar.state.fileUrl(toolbar.state.configPath)
        selectedFile: toolbar.state.fileUrl(toolbar.state.configPath)
        defaultSuffix: "json"
        nameFilters: ["JSON config (*.json)"]
        onAccepted: toolbar.configService.runTransfer("export-json", selectedFile)
    }

    Dialogs.FileDialog {
        id: exportZipDialog
        title: "Export workspace wallpaper bundle"
        fileMode: Dialogs.FileDialog.SaveFile
        currentFolder: toolbar.state.fileUrl(toolbar.state.home)
        selectedFile: toolbar.state.fileUrl(
            toolbar.state.home + "/workspace-wallpapers.zip"
        )
        defaultSuffix: "zip"
        nameFilters: ["ZIP bundle (*.zip)"]
        onAccepted: toolbar.configService.runTransfer("export-zip", selectedFile)
    }

    Controls.Label {
        Layouts.Layout.fillWidth: true
        text: toolbar.state.transferStatus
        color: toolbar.state.textSurfaceVariant
        font: Tokens.font.label.small
        elide: QQ.Text.ElideRight
    }

    QQ.Row {
        id: transferSplitButton
        spacing: Math.max(1, Math.round(Tokens.spacing.extraSmall / 2))

        QQ.Rectangle {
            width: 154
            height: 42
            radius: height / 2 * Math.min(1, Tokens.rounding.scale)
            color: importJsonMouse.enabled
                ? toolbar.state.primary
                : Qt.alpha(toolbar.state.textSurface, 0.10)

            QQ.Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.alpha(
                    toolbar.state.textPrimary,
                    importJsonMouse.pressed
                        ? 0.10
                        : importJsonMouse.containsMouse ? 0.08 : 0
                )
            }

            Layouts.RowLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                Controls.Label {
                    text: "file_open"
                    color: importJsonMouse.enabled
                        ? toolbar.state.textPrimary
                        : Qt.alpha(toolbar.state.textSurface, 0.38)
                    font: Tokens.font.icon.medium
                }

                Controls.Label {
                    text: "Import (JSON)"
                    color: importJsonMouse.enabled
                        ? toolbar.state.textPrimary
                        : Qt.alpha(toolbar.state.textSurface, 0.38)
                    font: Tokens.font.body.small
                }
            }

            QQ.MouseArea {
                id: importJsonMouse
                anchors.fill: parent
                enabled: !toolbar.configService.busy
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: importJsonDialog.open()
                Controls.ToolTip.visible: containsMouse
                Controls.ToolTip.delay: 500
                Controls.ToolTip.text:
                    "Import only a workspace wallpapers config."
            }
        }

        QQ.Rectangle {
            width: 42
            height: 42
            radius: height / 2 * Math.min(1, Tokens.rounding.scale)
            color: transferMenuMouse.enabled
                ? toolbar.state.primary
                : Qt.alpha(toolbar.state.textSurface, 0.10)

            QQ.Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.alpha(
                    toolbar.state.textPrimary,
                    transferMenuMouse.pressed
                        ? 0.10
                        : transferMenu.visible || transferMenuMouse.containsMouse
                            ? 0.08 : 0
                )
            }

            Controls.Label {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: "expand_more"
                color: transferMenuMouse.enabled
                    ? toolbar.state.textPrimary
                    : Qt.alpha(toolbar.state.textSurface, 0.38)
                font: Tokens.font.icon.medium
                rotation: transferMenu.visible ? 180 : 0

                QQ.Behavior on rotation {
                    QQ.NumberAnimation {
                        duration: Tokens.anim.durations.expressiveFastEffects
                        easing: Tokens.anim.expressiveFastEffects
                    }
                }
            }

            QQ.MouseArea {
                id: transferMenuMouse
                property bool menuVisibleOnPress: false
                anchors.fill: parent
                enabled: !toolbar.configService.busy
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: menuVisibleOnPress = transferMenu.visible
                onClicked: {
                    if (menuVisibleOnPress) {
                        transferMenu.close()
                        return
                    }
                    const point = transferSplitButton.mapToItem(
                        toolbar.popupParent,
                        0,
                        transferSplitButton.height + Tokens.spacing.small
                    )
                    transferMenu.x = toolbar.popupParent.width -
                        transferMenu.width - Tokens.padding.largeIncreased
                    transferMenu.y = point.y
                    transferMenu.open()
                }
                Controls.ToolTip.visible: containsMouse && !transferMenu.visible
                Controls.ToolTip.delay: 500
                Controls.ToolTip.text: "More import and export actions."
            }
        }
    }

    Controls.Popup {
        id: transferMenu
        parent: toolbar.popupParent
        x: toolbar.popupParent.width - width - Tokens.padding.largeIncreased
        y: transferSplitButton.mapToItem(
            toolbar.popupParent,
            0,
            transferSplitButton.height + Tokens.spacing.small
        ).y
        width: 350
        height: 210
        padding: 0
        popupType: Controls.Popup.Item
        closePolicy: Controls.Popup.CloseOnEscape |
            Controls.Popup.CloseOnReleaseOutside

        background: QQ.Rectangle {
            radius: Tokens.rounding.large
            color: toolbar.state.surfaceContainerLow
            border.width: 1
            border.color: toolbar.state.outlineVariant
        }

        TransferMenuItem {
            text: "Import (ZIP)"
            iconName: "folder_zip"
            description: "Import config, images, and videos from a ZIP bundle."
            x: 6; y: 6; width: transferMenu.width - 12; height: 66
            primaryContainerColor: toolbar.state.primaryContainer
            textPrimaryContainerColor: toolbar.state.textPrimaryContainer
            textColor: toolbar.state.textSurface
            mutedTextColor: toolbar.state.textSurfaceVariant
            onClicked: { transferMenu.close(); importZipDialog.open() }
        }
        TransferMenuItem {
            text: "Export (JSON)"
            iconName: "data_object"
            description: "Export only the config."
            x: 6; y: 72; width: transferMenu.width - 12; height: 66
            primaryContainerColor: toolbar.state.primaryContainer
            textPrimaryContainerColor: toolbar.state.textPrimaryContainer
            textColor: toolbar.state.textSurface
            mutedTextColor: toolbar.state.textSurfaceVariant
            onClicked: { transferMenu.close(); toolbar.openExportJsonDialog() }
        }
        TransferMenuItem {
            text: "Export (ZIP)"
            iconName: "archive"
            description: "Export config with all media assets in use."
            x: 6; y: 138; width: transferMenu.width - 12; height: 66
            primaryContainerColor: toolbar.state.primaryContainer
            textPrimaryContainerColor: toolbar.state.textPrimaryContainer
            textColor: toolbar.state.textSurface
            mutedTextColor: toolbar.state.textSurfaceVariant
            onClicked: { transferMenu.close(); exportZipDialog.open() }
        }
    }
}
