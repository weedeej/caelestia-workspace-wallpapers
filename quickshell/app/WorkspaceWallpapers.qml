import QtQuick as QQ
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    id: root

    QQ.Connections {
        target: Quickshell
        function onLastWindowClosed() { Qt.quit() }
    }

    AppState { id: state }

    PickerController {
        id: picker
        state: state
        configService: configService
        mediaService: mediaService
    }

    ConfigService {
        id: configService
        state: state
        picker: picker
        onRescanRequested: mediaService.rescan()
    }

    MediaService {
        id: mediaService
        state: state
        picker: picker
        configService: configService
    }

    ThemeService {
        id: themeService
        state: state
    }

    MainWindow {
        id: mainWindow
        state: state
        picker: picker
        configService: configService
        mediaService: mediaService
        themeService: themeService
    }

    HyprlandFocusGrab {
        windows: [mainWindow.pickerWindow]
        active: picker.open && !picker.closing && !picker.videoMatching
        onCleared: picker.close()
    }
}
