import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Quickshell.Widgets
import Caelestia.Config

ClippingRectangle {
    id: card

    required property string title
    required property string preview
    required property bool video
    required property bool random
    required property bool current
    required property bool removable

    required property var state

    property bool compact: false

    signal editRequested(var anchorItem)
    signal removeRequested()

    radius: compact ? Tokens.rounding.medium : Tokens.rounding.large
    color: card.state.surfaceContainerHigh
    border.width: current ? 2 : 0
    border.color: card.state.primary

    QQ.Behavior on color {
        QQ.ColorAnimation {
            duration: Tokens.anim.durations.expressiveSlowEffects
            easing: Tokens.anim.expressiveSlowEffects
        }
    }

    QQ.Image {
        anchors.fill: parent
        visible: card.preview.length > 0
        source: visible ? card.preview : ""
        fillMode: QQ.Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    QQ.Rectangle {
        anchors.fill: parent
        visible: card.random
        color: card.state.primaryContainer

        Controls.Label {
            anchors.centerIn: parent
            text: "casino"
            color: card.state.textPrimaryContainer
            font: card.compact
                ? Tokens.font.icon.large
                : Tokens.font.icon.extraLarge
        }
    }

    QQ.Rectangle {
        anchors.centerIn: parent
        visible: card.video && card.preview.length === 0
        width: card.compact ? 46 : 64
        height: width
        radius: height / 2 * Math.min(1, Tokens.rounding.scale)
        color: card.state.primaryContainer

        Controls.Label {
            anchors.centerIn: parent
            text: "play_arrow"
            color: card.state.textPrimaryContainer
            font: card.compact
                ? Tokens.font.icon.medium
                : Tokens.font.icon.large
        }
    }

    QQ.Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins:
            card.compact ? Tokens.padding.small : Tokens.padding.medium
        visible: card.video
        implicitWidth: badgeRow.implicitWidth + Tokens.padding.small * 2
        height: 24
        radius: height / 2 * Math.min(1, Tokens.rounding.scale)
        color: Qt.alpha(card.state.scrim, 0.62)

        Layouts.RowLayout {
            id: badgeRow
            anchors.centerIn: parent
            spacing: Math.max(1, Math.round(Tokens.spacing.extraSmall / 2))

            Controls.Label {
                text: "play_arrow"
                color: "white"
                font: Tokens.font.icon.small
            }

            Controls.Label {
                visible: !card.compact
                text: "VIDEO"
                color: "white"
                font: Tokens.font.label.small
            }
        }
    }

    QQ.HoverHandler { id: hover }

    QQ.Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: card.compact ? 36 : 52
        visible: hover.hovered
        color: Qt.alpha(card.state.scrim, card.compact ? 0.34 : 0.26)

        QQ.Rectangle {
            id: editButton
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: card.compact ? parent.left : undefined
            anchors.leftMargin: card.compact ? Tokens.padding.medium : 0
            anchors.horizontalCenter: card.compact ? undefined : parent.horizontalCenter
            width: card.compact ? 38 : 42
            height: width
            radius: height / 2 * Math.min(1, Tokens.rounding.scale)
            color: card.state.primaryContainer

            Controls.Label {
                anchors.centerIn: parent
                text: "edit"
                color: card.state.textPrimaryContainer
                font: Tokens.font.icon.medium
            }

            QQ.MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.editRequested(editButton)
            }
        }

        QQ.Rectangle {
            visible: card.removable
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: width
            radius: height / 2 * Math.min(1, Tokens.rounding.scale)
            color: Qt.alpha(card.state.scrim, 0.34)

            Controls.Label {
                anchors.centerIn: parent
                text: "delete"
                color: card.state.error
                font: Tokens.font.icon.medium
            }

            QQ.MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.removeRequested()
            }
        }
    }

    QQ.Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: card.compact ? 36 : 52
        color: Qt.alpha(card.state.scrim, 0.63)

        Controls.Label {
            anchors.fill: parent
            anchors.leftMargin:
                card.compact ? Tokens.padding.small : Tokens.padding.large
            anchors.rightMargin:
                card.compact ? Tokens.padding.small : Tokens.padding.large
            text: card.title
            color: "white"
            font: card.compact
                ? Tokens.font.label.small
                : Tokens.font.body.small
            elide: QQ.Text.ElideMiddle
            verticalAlignment: QQ.Text.AlignVCenter
        }
    }
}
