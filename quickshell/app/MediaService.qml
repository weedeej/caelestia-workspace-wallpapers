import QtQuick as QQ
import Quickshell.Io

QQ.Item {
    id: service

    required property var state
    required property var picker
    required property var configService
    visible: false

    function rescan() {
        if (!mediaScanner.running)
            mediaScanner.exec([state.mediaHelperPath, "scan"])
    }

    function loadTimeline() {
        if (!picker.selectedVideoPath || timelineGenerator.running)
            return
        picker.timelineLoading = true
        picker.timelineFrames = []
        state.mediaError = ""
        timelineGenerator.exec([
            state.mediaHelperPath, "timeline", picker.selectedVideoPath,
            picker.selectedVideoInterval.toString()
        ])
    }

    function commitVideo() {
        if (!picker.selectedVideoPath ||
                (!picker.pickingDefault && picker.selectedWorkspace <= 0) ||
                configService.busy || videoMatcher.running)
            return
        state.mediaError = ""
        picker.optimizedVideoPath = ""
        picker.optimizedVideoWidth = picker.targetVideoWidth()
        picker.optimizedVideoHeight = picker.targetVideoHeight()
        picker.videoMatching = true
        videoMatcher.exec([
            state.mediaHelperPath, "optimize", picker.selectedVideoPath,
            picker.optimizedVideoWidth.toString(),
            picker.optimizedVideoHeight.toString()
        ])
    }

    Process {
        id: mediaScanner
        command: [service.state.mediaHelperPath, "scan"]
        running: true

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim()
                if (message.length > 0)
                    console.warn("Media scan:", message)
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim()
                    service.state.mediaItems = raw.length > 0
                        ? JSON.parse(raw) : []
                } catch (error) {
                    console.warn("Unable to parse media list:", error)
                }
            }
        }
    }

    Process {
        id: timelineGenerator
        stderr: MediaErrorCollector { state: service.state }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim()
                    if (raw.length > 0) {
                        const result = JSON.parse(raw)
                        service.picker.timelineFrames = result.frames || []
                        service.picker.selectedVideoDuration =
                            Number(result.duration) || 0
                        if (service.picker.selectedVideoFrame >
                                service.picker.selectedVideoDuration) {
                            service.picker.selectedVideoFrame =
                                service.picker.selectedVideoDuration
                        }
                    }
                } catch (error) {
                    service.state.mediaError = "Unable to parse video timeline."
                }
                service.picker.timelineLoading = false
            }
        }
    }

    Process {
        id: videoMatcher
        property bool resultReady: false
        stderr: MediaErrorCollector { state: service.state }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text.trim())
                    service.picker.optimizedVideoPath = String(result.path || "")
                    service.picker.optimizedVideoWidth = Number(result.width) || 0
                    service.picker.optimizedVideoHeight = Number(result.height) || 0
                    videoMatcher.resultReady =
                        service.picker.optimizedVideoPath.length > 0 &&
                        service.picker.optimizedVideoWidth > 0 &&
                        service.picker.optimizedVideoHeight > 0
                } catch (error) {
                    service.state.mediaError =
                        "Unable to read the resolution-matched video."
                    videoMatcher.resultReady = false
                }
            }
        }
        onExited: function(exitCode) {
            service.picker.videoMatching = false
            if (exitCode === 0 && resultReady)
                service.configService.writeVideoConfig()
            resultReady = false
        }
    }
}
