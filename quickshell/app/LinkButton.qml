import QtQuick as QQ
import QtQuick.Controls as Controls
import Caelestia.Config

Controls.Button {
    id: button

    required property var primaryColor
    required property var disabledTextColor

    flat: true
    hoverEnabled: true
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    leftPadding: Tokens.padding.large
    rightPadding: Tokens.padding.large
    topPadding: Tokens.padding.small
    bottomPadding: Tokens.padding.small

    contentItem: Controls.Label {
        text: button.text
        color: button.enabled ? button.primaryColor : button.disabledTextColor
        font: Tokens.font.body.small
        horizontalAlignment: QQ.Text.AlignHCenter
        verticalAlignment: QQ.Text.AlignVCenter
    }

    background: QQ.Rectangle {
        radius: button.height / 2 * Math.min(1, Tokens.rounding.scale)
        color: Qt.alpha(
            button.primaryColor,
            button.down ? 0.10 : button.hovered ? 0.08 : 0
        )

        QQ.Behavior on color {
            QQ.ColorAnimation {
                duration: Tokens.anim.durations.expressiveSlowEffects
                easing: Tokens.anim.expressiveSlowEffects
            }
        }
    }
}
