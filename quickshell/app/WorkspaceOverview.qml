import QtQuick as QQ
import QtQuick.Controls as Controls
import QtQuick.Layouts as Layouts
import Caelestia.Config

Layouts.ColumnLayout {
    id: overview

    required property var state
    required property var picker
    required property var configService
    spacing: Tokens.spacing.large

    Controls.Label {
        text: "DEFAULT  (all non-custom use this)"
        color: overview.state.textSurfaceVariant
        font: Tokens.font.label.small
    }

    WallpaperCard {
        Layouts.Layout.fillWidth: true
        Layouts.Layout.preferredHeight: 180
        title: overview.state.entryName(overview.state.configData.default)
        preview: overview.state.fileUrl(
            overview.state.entryPreview(overview.state.configData.default)
        )
        video: overview.state.isVideoEntry(overview.state.configData.default)
        random: overview.state.isRandomEntry(overview.state.configData.default)
        current: false
        removable: false
        state: overview.state
        onEditRequested: function(anchorItem) {
            overview.picker.openDefault(anchorItem)
        }
    }

    Layouts.RowLayout {
        Layouts.Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Controls.Label {
            text: "WORKSPACES"
            color: overview.state.textSurfaceVariant
            font: Tokens.font.label.small
        }

        LinkButton {
            id: addWorkspaceButton
            text: "+ Add"
            state: overview.state
            onClicked: overview.picker.beginAddWorkspace(addWorkspaceButton)
        }

        QQ.Item { Layouts.Layout.fillWidth: true }
    }

    QQ.Flow {
        id: workspaceFlow
        Layouts.Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        readonly property int columnCount: Math.max(
            1, Math.floor((width + spacing) / (160 + spacing))
        )
        readonly property real cardWidth:
            (width - (columnCount - 1) * spacing) / columnCount

        QQ.Repeater {
            model: overview.state.overrideWorkspaceIds()

            delegate: QQ.Item {
                id: workspaceCard
                required property var modelData
                property int workspace: Number(modelData)
                property var entry: overview.state.workspaceEntry(workspace)
                width: workspaceFlow.cardWidth
                height: 138

                Layouts.ColumnLayout {
                    anchors.fill: parent
                    spacing: Tokens.spacing.extraSmall

                    Controls.Label {
                        text: "Workspace " + workspaceCard.workspace
                        color: overview.state.textSurface
                        font: overview.state.isCurrentWorkspace(
                            workspaceCard.workspace
                        ) ? Tokens.font.label.large : Tokens.font.label.medium
                    }

                    WallpaperCard {
                        Layouts.Layout.fillWidth: true
                        Layouts.Layout.fillHeight: true
                        compact: true
                        title: overview.state.entryName(workspaceCard.entry)
                        preview: overview.state.fileUrl(
                            overview.state.entryPreview(workspaceCard.entry)
                        )
                        video: overview.state.isVideoEntry(workspaceCard.entry)
                        random: overview.state.isRandomEntry(workspaceCard.entry)
                        current: overview.state.isCurrentWorkspace(
                            workspaceCard.workspace
                        )
                        removable: true
                        state: overview.state
                        onEditRequested: function(anchorItem) {
                            overview.picker.editWorkspace(
                                workspaceCard.workspace, anchorItem
                            )
                        }
                        onRemoveRequested: overview.configService.clearWorkspace(
                            workspaceCard.workspace
                        )
                    }
                }
            }
        }
    }
}
