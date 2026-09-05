import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Caelestia.Config

Controls.ComboBox {
    id: combo

    required property var state
    required property var configService
    enabled: state.showWorkspaceNumber && !configService.busy
    opacity: enabled ? 1 : 0.38
    QQ.Accessible.name: "Workspace number position"
    Layouts.Layout.preferredWidth: labelMetrics.advanceWidth + leftPadding + rightPadding
    Layouts.Layout.preferredHeight: implicitHeight
    implicitHeight: Math.max(labelMetrics.height, indicator.implicitHeight) + Tokens.padding.small * 2
    hoverEnabled: true
    Controls.ToolTip.visible: hovered
    Controls.ToolTip.delay: 500
    Controls.ToolTip.text: "Workspace number position"

    QQ.TextMetrics {
        id: labelMetrics
        font: combo.Tokens.font.body.small
        text: "Bottom right"
    }
    leftPadding: Tokens.padding.medium
    rightPadding: Tokens.padding.extraLargeIncreased
    model: state.workspaceNumberPositionLabels
    currentIndex: state.workspaceNumberPositions.indexOf(state.workspaceNumberPosition)

    contentItem: Controls.Label {
        text: combo.displayText
        color: combo.state.textSurface
        font: Tokens.font.body.small
        elide: QQ.Text.ElideRight
        verticalAlignment: QQ.Text.AlignVCenter
    }

    indicator: Controls.Label {
        x: combo.width - width - Tokens.padding.medium
        y: combo.topPadding + (combo.availableHeight - height) / 2
        text: "expand_more"
        color: combo.state.textSurfaceVariant
        font: Tokens.font.icon.medium
        rotation: combo.popup.visible ? 180 : 0

        QQ.Behavior on rotation {
            QQ.NumberAnimation {
                duration: combo.Tokens.anim.durations.expressiveFastEffects
                easing: combo.Tokens.anim.expressiveFastEffects
            }
        }
    }

    background: QQ.Rectangle {
        radius: Tokens.rounding.full
        color:
            combo.pressed
                ? combo.state.surfaceContainerHighest
                : combo.hovered || combo.popup.visible
                    ? combo.state.surfaceContainerHigh
                    : combo.state.surfaceContainerLow
        border.width: combo.popup.visible || combo.visualFocus ? 2 : 1
        border.color:
            combo.popup.visible || combo.visualFocus
                ? combo.state.primary
                : combo.hovered
                    ? combo.state.outline : combo.state.outlineVariant

        QQ.Behavior on color {
            QQ.ColorAnimation {
                duration: combo.Tokens.anim.durations.expressiveSlowEffects
                easing: combo.Tokens.anim.expressiveSlowEffects
            }
        }
        QQ.Behavior on border.color {
            QQ.ColorAnimation {
                duration: combo.Tokens.anim.durations.expressiveSlowEffects
                easing: combo.Tokens.anim.expressiveSlowEffects
            }
        }
    }

    delegate: Controls.ItemDelegate {
        id: option
        required property var modelData
        required property int index
        width: combo.popup.availableWidth
        height: combo.implicitHeight
        leftPadding: Tokens.padding.medium
        rightPadding: Tokens.padding.medium
        highlighted: combo.highlightedIndex === index

        background: QQ.Rectangle {
            radius: Tokens.rounding.medium
            color: option.highlighted
                ? combo.state.primaryContainer : "transparent"
        }

        contentItem: Layouts.RowLayout {
            spacing: Tokens.spacing.small

            Controls.Label {
                text: option.index === combo.currentIndex ? "check" : ""
                color: option.highlighted
                    ? combo.state.textPrimaryContainer
                    : option.index === combo.currentIndex
                        ? combo.state.primary : combo.state.textSurfaceVariant
                font: Tokens.font.icon.medium
                Layouts.Layout.preferredWidth: implicitHeight
            }

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: option.modelData
                color: option.highlighted
                    ? combo.state.textPrimaryContainer
                    : combo.state.textSurface
                font: Tokens.font.body.small
            }
        }
    }

    popup: Controls.Popup {
        // Popups are reparented to the overlay; explicitly retain monitor tokens.
        Tokens.screen: combo.Tokens.screen
        Config.screen: combo.Config.screen
        y: combo.height + Tokens.spacing.small
        width: combo.width + combo.Tokens.spacing.medium + combo.Tokens.font.icon.medium.pointSize
        x: combo.width - width
        padding: Tokens.padding.extraSmall
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding

        contentItem: QQ.ListView {
            clip: true
            implicitHeight: contentHeight
            model: combo.popup.visible ? combo.delegateModel : null
            currentIndex: combo.highlightedIndex
            highlightMoveDuration: 0
            Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
        }

        background: QQ.Rectangle {
            radius: Tokens.rounding.large
            color: combo.state.surfaceContainerLow
            border.width: 1
            border.color: combo.state.outlineVariant
        }
    }

    onActivated: index => configService.setWorkspaceNumberPosition(
        state.workspaceNumberPositions[index]
    )
}
