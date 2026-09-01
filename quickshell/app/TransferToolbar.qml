import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Dialogs as Dialogs
import QtQuick.Layouts as Layouts
import "PathUtils.js" as PathUtils

Layouts.RowLayout {
    id: toolbar

    required property var state
    required property var configService
    required property var popupParent
    Layouts.Layout.fillWidth: true
    spacing: 8

    function openExportJsonDialog() {
        const path = state.configPath
        const folder = path.slice(0, path.lastIndexOf("/"))
        exportJsonDialog.currentFolder = PathUtils.fileUrl(folder)
        exportJsonDialog.currentFile = PathUtils.fileUrl(path)
        exportJsonDialog.selectedFile = PathUtils.fileUrl(path)
        exportJsonDialog.open()
    }

    Dialogs.FileDialog {
        id: importJsonDialog
        title: "Import workspace wallpaper config"
        fileMode: Dialogs.FileDialog.OpenFile
        currentFolder: PathUtils.fileUrl(toolbar.state.home)
        nameFilters: ["JSON config (*.json)"]
        onAccepted: toolbar.configService.runTransfer("import-json", selectedFile)
    }

    Dialogs.FileDialog {
        id: importZipDialog
        title: "Import workspace wallpaper bundle"
        fileMode: Dialogs.FileDialog.OpenFile
        currentFolder: PathUtils.fileUrl(toolbar.state.home)
        nameFilters: ["ZIP bundle (*.zip)"]
        onAccepted: toolbar.configService.runTransfer("import-zip", selectedFile)
    }

    Dialogs.FileDialog {
        id: exportJsonDialog
        title: "Export workspace wallpaper config"
        fileMode: Dialogs.FileDialog.SaveFile
        currentFolder: PathUtils.fileUrl(
            toolbar.state.configPath.slice(
                0, toolbar.state.configPath.lastIndexOf("/")
            )
        )
        currentFile: PathUtils.fileUrl(toolbar.state.configPath)
        selectedFile: PathUtils.fileUrl(toolbar.state.configPath)
        defaultSuffix: "json"
        nameFilters: ["JSON config (*.json)"]
        onAccepted: toolbar.configService.runTransfer("export-json", selectedFile)
    }

    Dialogs.FileDialog {
        id: exportZipDialog
        title: "Export workspace wallpaper bundle"
        fileMode: Dialogs.FileDialog.SaveFile
        currentFolder: PathUtils.fileUrl(toolbar.state.home)
        selectedFile: PathUtils.fileUrl(
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
        font.pixelSize: 11
        elide: QQ.Text.ElideRight
    }

    QQ.Row {
        id: transferSplitButton
        spacing: 3

        QQ.Rectangle {
            width: 154
            height: 42
            radius: 21
            color:
                !importJsonMouse.enabled
                    ? Qt.alpha(toolbar.state.primary, 0.38)
                    : importJsonMouse.pressed
                        ? Qt.darker(toolbar.state.primary, 1.12)
                        : importJsonMouse.containsMouse
                            ? Qt.lighter(toolbar.state.primary, 1.06)
                            : toolbar.state.primary

            Layouts.RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Controls.Label {
                    text: "file_open"
                    color: importJsonMouse.enabled
                        ? toolbar.state.textPrimary
                        : Qt.alpha(toolbar.state.textSurface, 0.38)
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 19
                }
                Controls.Label {
                    text: "Import (JSON)"
                    color: importJsonMouse.enabled
                        ? toolbar.state.textPrimary
                        : Qt.alpha(toolbar.state.textSurface, 0.38)
                    font.pixelSize: 13
                    font.weight: 600
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
            QQ.Behavior on color { QQ.ColorAnimation { duration: 120 } }
        }

        QQ.Rectangle {
            width: 42
            height: 42
            radius: 21
            color:
                !transferMenuMouse.enabled
                    ? Qt.alpha(toolbar.state.primary, 0.38)
                    : transferMenuMouse.pressed
                        ? Qt.darker(toolbar.state.primary, 1.12)
                        : transferMenu.visible || transferMenuMouse.containsMouse
                            ? Qt.lighter(toolbar.state.primary, 1.06)
                            : toolbar.state.primary

            Controls.Label {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: "expand_more"
                color: transferMenuMouse.enabled
                    ? toolbar.state.textPrimary
                    : Qt.alpha(toolbar.state.textSurface, 0.38)
                font.family: "Material Symbols Rounded"
                font.pixelSize: 21
                rotation: transferMenu.visible ? 180 : 0
                QQ.Behavior on rotation {
                    QQ.NumberAnimation { duration: 160 }
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
                        toolbar.popupParent, 0, transferSplitButton.height + 8
                    )
                    transferMenu.x = toolbar.popupParent.width -
                        transferMenu.width - 20
                    transferMenu.y = point.y
                    transferMenu.open()
                }
                Controls.ToolTip.visible: containsMouse && !transferMenu.visible
                Controls.ToolTip.delay: 500
                Controls.ToolTip.text: "More import and export actions."
            }
            QQ.Behavior on color { QQ.ColorAnimation { duration: 120 } }
        }
    }

    Controls.Popup {
        id: transferMenu
        parent: toolbar.popupParent
        x: toolbar.popupParent.width - width - 20
        y: transferSplitButton.mapToItem(
            toolbar.popupParent, 0, transferSplitButton.height + 8
        ).y
        width: 350
        height: 210
        padding: 0
        popupType: Controls.Popup.Item
        closePolicy: Controls.Popup.CloseOnEscape |
            Controls.Popup.CloseOnReleaseOutside
        background: QQ.Rectangle {
            radius: 16
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
