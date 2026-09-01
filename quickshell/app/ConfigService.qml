import QtQuick as QQ
import Quickshell.Io
import Quickshell.Hyprland

QQ.Item {
    id: service

    required property var state
    required property var picker
    readonly property bool busy:
        transferProcess.running || configWriter.running || state.transferMatching
    property bool pendingZipMatch: false
    signal rescanRequested()
    signal zipImportReady()

    visible: false

    function localPath(fileUrl) {
        return decodeURIComponent(
            String(fileUrl).replace(/^file:\/\/(?:localhost)?/, "")
        )
    }

    function runTransfer(action, fileUrl) {
        if (transferProcess.running || !fileUrl)
            return
        state.transferStatus = "Working…"
        state.transferImporting = action.startsWith("import-")
        transferProcess.action = action
        transferProcess.exec([
            state.helperPath, action, localPath(fileUrl)
        ])
    }

    function applyWorkspace(workspace) {
        if (workspace > 0)
            applyWallpaper.exec([state.applyPath, workspace.toString()])
    }

    function prepareConfigWrite(closePickerOnSuccess, requireIdle) {
        if (requireIdle && (configWriter.running || transferProcess.running))
            return false
        state.configWriteError = ""
        configWriter.closePickerOnSuccess = closePickerOnSuccess
        configWriter.pendingApplyWorkspace = picker.preparePendingApply()
        return true
    }

    function assignSimpleEntry(value) {
        if (!prepareConfigWrite(true, true))
            return
        if (picker.pickingDefault) {
            configWriter.exec([state.helperPath, "set-default", value])
        } else if (picker.selectedWorkspace > 0) {
            configWriter.exec([
                state.helperPath, "set",
                picker.selectedWorkspace.toString(), value
            ])
        }
    }

    function writeVideoConfig() {
        if (!picker.optimizedVideoPath || !prepareConfigWrite(true, false))
            return
        const values = [
            picker.selectedVideoPath,
            Number(picker.selectedVideoFrame.toFixed(3)).toString(),
            picker.selectedVideoInterval.toString(),
            picker.optimizedVideoPath,
            picker.optimizedVideoWidth.toString(),
            picker.optimizedVideoHeight.toString()
        ]
        if (picker.pickingDefault) {
            configWriter.exec(
                [state.helperPath, "set-video-default"].concat(values)
            )
        } else {
            configWriter.exec([
                state.helperPath, "set-video",
                picker.selectedWorkspace.toString()
            ].concat(values))
        }
    }

    function clearWorkspace(workspace) {
        if (workspace <= 0 || busy || picker.videoMatching)
            return
        state.configWriteError = ""
        configWriter.pendingApplyWorkspace =
            state.isCurrentWorkspace(workspace) ? workspace : -1
        configWriter.closePickerOnSuccess = false
        configWriter.exec([
            state.helperPath, "clear", workspace.toString()
        ])
    }

    function reloadConfig() {
        configFile.reload()
    }

    function finishImport() {
        configFile.reload()
        rescanRequested()
        if (Hyprland.focusedWorkspace)
            applyWorkspace(Hyprland.focusedWorkspace.id)
        state.transferImporting = false
    }

    FileView {
        id: configFile
        path: service.state.configPath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const raw = text()
                if (raw && raw.length > 0)
                    service.state.configData = JSON.parse(raw)
                if (service.pendingZipMatch) {
                    service.pendingZipMatch = false
                    service.zipImportReady()
                }
            } catch (error) {
                console.warn("Unable to read workspace wallpaper config:", error)
            }
        }
    }

    Process {
        id: configWriter
        property int pendingApplyWorkspace: -1
        property bool closePickerOnSuccess: false

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()
                if (message.length > 0)
                    service.state.configWriteError = message
            }
        }

        onExited: function(exitCode) {
            if (exitCode === 0) {
                configFile.reload()
                if (closePickerOnSuccess)
                    service.picker.close()
                if (pendingApplyWorkspace > 0)
                    service.applyWorkspace(pendingApplyWorkspace)
            }
            pendingApplyWorkspace = -1
            closePickerOnSuccess = false
        }
    }

    Process { id: applyWallpaper }

    Process {
        id: transferProcess
        property string action: ""

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()
                if (message.length > 0)
                    service.state.transferStatus = message
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const message = text.trim()
                if (message.length > 0)
                    service.state.transferStatus = message
            }
        }
        onExited: function(exitCode) {
            if (exitCode === 0 && service.state.transferImporting) {
                if (action === "import-zip") {
                    service.pendingZipMatch = true
                    configFile.reload()
                    return
                }
                service.finishImport()
            }
            service.state.transferImporting = false
        }
    }

}
