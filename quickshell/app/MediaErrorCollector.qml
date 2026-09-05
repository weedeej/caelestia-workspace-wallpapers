import Quickshell.Io

StdioCollector {
    required property var state

    onStreamFinished: {
        const message = text.trim()
        if (message.length > 0)
            state.mediaError = message
    }
}
