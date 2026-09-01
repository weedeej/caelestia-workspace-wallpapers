import QtQuick as QQ
import QtQuick.Controls as Controls

Controls.Button {
    id: button

    required property var primaryColor
    required property var disabledTextColor

    flat: true
    hoverEnabled: true
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 42
    leftPadding: 16
    rightPadding: 16

    contentItem: Controls.Label {
        text: button.text
        color: button.enabled ? button.primaryColor : button.disabledTextColor
        font.pixelSize: 13
        font.weight: 600
        horizontalAlignment: QQ.Text.AlignHCenter
        verticalAlignment: QQ.Text.AlignVCenter
    }

    background: QQ.Rectangle {
        radius: 21
        color:
            button.down
                ? Qt.alpha(button.primaryColor, 0.16)
                : button.hovered
                    ? Qt.alpha(button.primaryColor, 0.10)
                    : "transparent"
        border.width: 0

        QQ.Behavior on color {
            QQ.ColorAnimation {
                duration: 120
            }
        }
    }
}
