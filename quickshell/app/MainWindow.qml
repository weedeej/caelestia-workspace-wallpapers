import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Quickshell

FloatingWindow {
    id: window

    required property var state
    required property var picker
    required property var configService
    required property var mediaService
    required property var themeService
    readonly property alias pickerWindow: pickerPanel

    title: "Workspace Wallpapers"
    implicitWidth: 780
    implicitHeight: 650
    minimumSize: Qt.size(580, 480)
    QQ.Component.onCompleted: picker.window = window

    QQ.Rectangle {
        id: themeLayer
        anchors.fill: parent
        color: window.state.surface
        onWidthChanged: window.picker.position()
        onHeightChanged: window.picker.position()

        QQ.Connections {
            target: mainScroll.contentItem
            function onContentXChanged() { window.picker.position() }
            function onContentYChanged() { window.picker.position() }
        }
        QQ.Connections {
            target: window.themeService
            function onSwapRequested() { themeSwapAnimation.restart() }
        }

        Layouts.ColumnLayout {
            anchors.fill: parent
            spacing: 0
            QQ.Rectangle {
                Layouts.Layout.fillWidth: true
                Layouts.Layout.preferredHeight: 12
                color: window.state.surfaceContainer
                QQ.MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.SizeAllCursor
                    onPressed: window.startSystemMove()
                }
            }

            Controls.ScrollView {
                id: mainScroll
                Layouts.Layout.fillWidth: true
                Layouts.Layout.fillHeight: true
                clip: true
                QQ.Item {
                    implicitWidth: window.width
                    implicitHeight: content.implicitHeight + 40
                    Layouts.ColumnLayout {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        anchors.topMargin: 20
                        spacing: 18

                        TransferToolbar {
                            state: window.state
                            configService: window.configService
                            popupParent: themeLayer
                        }
                        WorkspaceOverview {
                            Layouts.Layout.fillWidth: true
                            state: window.state
                            picker: window.picker
                            configService: window.configService
                        }
                        PickerPanel {
                            id: pickerPanel
                            state: window.state
                            picker: window.picker
                            mediaService: window.mediaService
                        }
                    }
                }
            }
        }

        QQ.SequentialAnimation {
            id: themeSwapAnimation
            QQ.NumberAnimation {
                target: themeLayer
                property: "opacity"
                to: 0.12
                duration: 85
                easing.type: QQ.Easing.InQuad
            }
            QQ.ScriptAction {
                script: {
                    if (window.state.pendingSchemeData !== null) {
                        window.state.schemeData = window.state.pendingSchemeData
                        window.state.pendingSchemeData = null
                    }
                }
            }
            QQ.NumberAnimation {
                target: themeLayer
                property: "opacity"
                to: 1
                duration: 170
                easing.type: QQ.Easing.OutCubic
            }
        }
    }
}
