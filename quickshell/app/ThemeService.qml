import QtQuick as QQ
import Quickshell.Io

QQ.Item {
    id: service

    required property var state
    signal swapRequested()
    visible: false

    FileView {
        path: service.state.schemePath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const raw = text()
                if (raw && raw.length > 0) {
                    const parsed = JSON.parse(raw)
                    if (!service.state.schemeReady) {
                        service.state.schemeData = parsed
                        service.state.schemeReady = true
                    } else {
                        service.state.pendingSchemeData = parsed
                        service.swapRequested()
                    }
                }
            } catch (error) {
                console.warn("Unable to read Caelestia scheme:", error)
            }
        }
    }
}
