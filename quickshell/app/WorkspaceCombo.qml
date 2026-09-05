import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Caelestia.Config

Controls.ComboBox {
    id: combo

    required property var state
    required property var picker
    enabled: !picker.videoMatching
    Layouts.Layout.preferredWidth: 194
    Layouts.Layout.preferredHeight: 42
    leftPadding: Tokens.padding.medium
    rightPadding: Tokens.padding.extraLargeIncreased
    model: state.pickerWorkspaceOptions(picker.selectedWorkspace)

    currentIndex: {
        if (picker.selectedWorkspace <= 0)
            return 0
        const index = model.indexOf(String(picker.selectedWorkspace))
        return index >= 0 ? index : 0
    }

    displayText: currentIndex > 0
        ? "Workspace " + model[currentIndex] : model[0]

    contentItem: Layouts.RowLayout {
        spacing: Tokens.spacing.small

        Controls.Label {
            text: "grid_view"
            color: combo.currentIndex > 0
                ? combo.state.primary : combo.state.textSurfaceVariant
            font: Tokens.font.icon.medium
        }

        Controls.Label {
            Layouts.Layout.fillWidth: true
            text: combo.displayText
            color: combo.currentIndex > 0
                ? combo.state.textSurface : combo.state.textSurfaceVariant
            font: combo.currentIndex > 0
                ? Tokens.font.label.large : Tokens.font.body.small
            elide: QQ.Text.ElideRight
            verticalAlignment: QQ.Text.AlignVCenter
        }
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
                duration: Tokens.anim.durations.expressiveFastEffects
                easing: Tokens.anim.expressiveFastEffects
            }
        }
    }

    background: QQ.Rectangle {
        radius: combo.height / 2 * Math.min(1, Tokens.rounding.scale)
        color:
            combo.pressed
                ? combo.state.surfaceContainerHighest
                : combo.hovered || combo.popup.visible
                    ? combo.state.surfaceContainerHigh
                    : combo.state.surfaceContainerLow
        border.width: combo.popup.visible ? 2 : 1
        border.color:
            combo.popup.visible
                ? combo.state.primary
                : combo.hovered
                    ? combo.state.outline : combo.state.outlineVariant

        QQ.Behavior on color {
            QQ.ColorAnimation {
                duration: Tokens.anim.durations.expressiveSlowEffects
                easing: Tokens.anim.expressiveSlowEffects
            }
        }
        QQ.Behavior on border.color {
            QQ.ColorAnimation {
                duration: Tokens.anim.durations.expressiveSlowEffects
                easing: Tokens.anim.expressiveSlowEffects
            }
        }
    }

    delegate: Controls.ItemDelegate {
        id: option
        required property var modelData
        required property int index
        width: combo.popup.width - Tokens.padding.medium
        height: 42
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
                text: option.index === combo.currentIndex
                    ? "check" : option.index === 0
                        ? "select_check_box" : "grid_view"
                color: option.highlighted
                    ? combo.state.textPrimaryContainer
                    : option.index === combo.currentIndex
                        ? combo.state.primary : combo.state.textSurfaceVariant
                font: Tokens.font.icon.medium
            }

            Controls.Label {
                Layouts.Layout.fillWidth: true
                text: option.index > 0
                    ? "Workspace " + option.modelData : option.modelData
                color: option.highlighted
                    ? combo.state.textPrimaryContainer
                    : combo.state.textSurface
                font: Tokens.font.body.small
            }
        }
    }

    popup: Controls.Popup {
        y: combo.height + Tokens.spacing.small
        width: combo.width
        padding: Tokens.padding.extraSmall
        implicitHeight: Math.min(
            contentItem.implicitHeight + Tokens.padding.small, 280
        )

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

    onActivated: {
        picker.resetVideoEditor()
        picker.target = {
            "kind": "workspace",
            "id": currentIndex > 0 ? Number(model[currentIndex]) : -1
        }
    }
}
