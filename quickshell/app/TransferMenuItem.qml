import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts

Controls.MenuItem {
    id: item

    required property string iconName
    required property string description
    required property var primaryContainerColor
    required property var textPrimaryContainerColor
    required property var textColor
    required property var mutedTextColor

    leftPadding: 12
    rightPadding: 12
    hoverEnabled: true

    background: QQ.Rectangle {
        radius: 11
        color:
            item.highlighted || item.hovered
                ? item.primaryContainerColor
                : "transparent"
    }

    contentItem: Layouts.RowLayout {
        spacing: 11

        Controls.Label {
            text: item.iconName
            color:
                item.highlighted || item.hovered
                    ? item.textPrimaryContainerColor
                    : item.mutedTextColor
            font.family: "Material Symbols Rounded"
            font.pixelSize: 19
        }

        Layouts.ColumnLayout {
            Layouts.Layout.fillWidth: true
            spacing: 2

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: item.text
                color:
                    item.highlighted || item.hovered
                        ? item.textPrimaryContainerColor
                        : item.textColor
                font.pixelSize: 13
                font.weight: 600
            }

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: item.description
                color:
                    item.highlighted || item.hovered
                        ? Qt.alpha(item.textPrimaryContainerColor, 0.78)
                        : item.mutedTextColor
                font.pixelSize: 11
                elide: QQ.Text.ElideRight
            }
        }
    }
}
