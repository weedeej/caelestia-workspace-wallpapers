import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Caelestia.Config

QQ.Rectangle {
    id: settings

    required property var state
    required property var configService
    implicitHeight: content.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.large
    color: state.surfaceContainerLow
    border.width: 1
    border.color: state.outlineVariant

    Layouts.RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        Controls.Switch {
            id: toggle
            Layouts.Layout.fillWidth: true
            implicitHeight: Math.max(implicitIndicatorHeight, contentItem.implicitHeight) + topPadding + bottomPadding
            text: "Show workspace number on switch"
            checked: settings.state.showWorkspaceNumber
            enabled: !settings.configService.busy
            hoverEnabled: true
            leftPadding: 0
            rightPadding: implicitIndicatorWidth + Tokens.spacing.medium
            topPadding: Tokens.padding.extraSmall
            bottomPadding: Tokens.padding.extraSmall
            onClicked: settings.configService.setShowWorkspaceNumber(checked)

            contentItem: Controls.Label {
                text: toggle.text
                font: Tokens.font.body.small
                color: Qt.alpha(settings.state.textSurface, toggle.enabled ? 1 : 0.38)
                verticalAlignment: QQ.Text.AlignVCenter
                wrapMode: QQ.Text.WordWrap
            }

            indicator: QQ.Rectangle {
                x: toggle.width - width
                y: (toggle.height - height) / 2
                implicitWidth: implicitHeight * 1.7
                implicitHeight: Tokens.font.body.medium.pointSize + Tokens.padding.small * 2
                width: implicitWidth
                height: implicitHeight
                radius: Tokens.rounding.full
                opacity: toggle.enabled ? 1 : 0.38
                color: toggle.checked ? settings.state.primary : settings.state.surfaceContainerHighest

                QQ.Rectangle {
                    anchors.fill: parent
                    anchors.margins: -Tokens.padding.extraSmall / 2
                    radius: Tokens.rounding.full
                    color: "transparent"
                    border.width: toggle.visualFocus ? 2 : 0
                    border.color: settings.state.primary
                }

                QQ.Rectangle {
                    x: toggle.checked
                        ? parent.width - width - Tokens.padding.extraSmall / 2
                        : Tokens.padding.extraSmall / 2
                    y: (parent.height - height) / 2
                    width: height * (toggle.down ? 1.2 : 1)
                    height: parent.height - Tokens.padding.extraSmall
                    radius: Tokens.rounding.full
                    color: toggle.checked ? settings.state.textPrimary : settings.state.outline

                    Controls.Label {
                        anchors.centerIn: parent
                        text: toggle.checked ? "check" : "close"
                        font: Tokens.font.icon.small
                        color: toggle.checked ? settings.state.primary : settings.state.surfaceContainerHighest
                    }

                    QQ.Behavior on x {
                        QQ.NumberAnimation {
                            duration: settings.Tokens.anim.durations.expressiveFastSpatial
                            easing: settings.Tokens.anim.expressiveFastSpatial
                        }
                    }
                }

                QQ.Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(settings.state.textSurface, toggle.down ? 0.10 : toggle.hovered ? 0.08 : 0)
                }

                QQ.Behavior on color {
                    QQ.ColorAnimation {
                        duration: settings.Tokens.anim.durations.expressiveFastEffects
                        easing: settings.Tokens.anim.expressiveFastEffects
                    }
                }
            }

            background: QQ.Item {}
        }

        WorkspaceNumberPositionCombo {
            state: settings.state
            configService: settings.configService
        }
    }
}
