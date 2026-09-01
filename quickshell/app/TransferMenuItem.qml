import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Caelestia.Config

Controls.MenuItem {
    id: item

    required property string iconName
    required property string description
    required property var primaryContainerColor
    required property var textPrimaryContainerColor
    required property var textColor
    required property var mutedTextColor

    leftPadding: Tokens.padding.medium
    rightPadding: Tokens.padding.medium
    hoverEnabled: true

    background: QQ.Rectangle {
        radius: Tokens.rounding.medium
        color:
            item.highlighted || item.hovered
                ? item.primaryContainerColor
                : "transparent"

        QQ.Behavior on color {
            QQ.ColorAnimation {
                duration: Tokens.anim.durations.expressiveSlowEffects
                easing: Tokens.anim.expressiveSlowEffects
            }
        }
    }

    contentItem: Layouts.RowLayout {
        spacing: Tokens.spacing.medium

        Controls.Label {
            text: item.iconName
            color:
                item.highlighted || item.hovered
                    ? item.textPrimaryContainerColor
                    : item.mutedTextColor
            font: Tokens.font.icon.medium
        }

        Layouts.ColumnLayout {
            Layouts.Layout.fillWidth: true
            spacing: Math.max(1, Math.round(Tokens.spacing.extraSmall / 2))

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: item.text
                color:
                    item.highlighted || item.hovered
                        ? item.textPrimaryContainerColor
                        : item.textColor
                font: Tokens.font.label.medium
            }

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: item.description
                color:
                    item.highlighted || item.hovered
                        ? Qt.alpha(item.textPrimaryContainerColor, 0.78)
                        : item.mutedTextColor
                font: Tokens.font.label.small
                elide: QQ.Text.ElideRight
            }
        }
    }
}
