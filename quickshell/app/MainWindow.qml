import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Quickshell
import Caelestia.Config

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
    color: "transparent"

    contentItem.Config.screen: screen ? screen.name : ""
    contentItem.Tokens.screen: screen ? screen.name : ""

    QQ.Component.onCompleted: picker.window = window

    QQ.Rectangle {
        id: themeLayer
        anchors.fill: parent
        color: window.state.surface
        onWidthChanged: window.picker.position()
        onHeightChanged: window.picker.position()

        QQ.Behavior on color {
            QQ.ColorAnimation {
                duration: Tokens.anim.durations.expressiveSlowEffects
                easing: Tokens.anim.expressiveSlowEffects
            }
        }

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
                Layouts.Layout.preferredHeight: Tokens.spacing.medium
                color: window.state.surfaceContainer

                QQ.Behavior on color {
                    QQ.ColorAnimation {
                        duration: Tokens.anim.durations.expressiveSlowEffects
                        easing: Tokens.anim.expressiveSlowEffects
                    }
                }

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
                    implicitHeight:
                        content.implicitHeight + Tokens.padding.largeIncreased * 2

                    Layouts.ColumnLayout {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        anchors.topMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.large

                        TransferToolbar {
                            state: window.state
                            configService: window.configService
                            popupParent: themeLayer
                        }

                        WorkspaceNumberSettings {
                            Layouts.Layout.fillWidth: true
                            state: window.state
                            configService: window.configService
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

        QQ.Rectangle {
            anchors.fill: parent
            z: 100
            visible: window.state.transferMatching
            color: Qt.alpha(window.state.scrim, 0.58)

            QQ.MouseArea { anchors.fill: parent }

            Layouts.RowLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.medium

                Controls.BusyIndicator {
                    running: parent.parent.visible
                }

                Controls.Label {
                    text: window.state.transferStatus
                    color: window.state.textSurface
                    font: Tokens.font.body.medium
                }
            }
        }

        QQ.SequentialAnimation {
            id: themeSwapAnimation

            QQ.NumberAnimation {
                target: themeLayer
                property: "opacity"
                to: 0.12
                duration: Tokens.anim.durations.expressiveFastEffects
                easing: Tokens.anim.expressiveFastEffects
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
                duration: Tokens.anim.durations.expressiveDefaultEffects
                easing: Tokens.anim.expressiveDefaultEffects
            }
        }
    }
}
