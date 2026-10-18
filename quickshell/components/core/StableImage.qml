import QtQuick

Item {
    id: root

    property url source
    property size sourceSize: Qt.size(0, 0)
    property int fillMode: Image.PreserveAspectFit
    property bool retain: true
    property bool mipmap: true
    property bool everReady: false
    property int retries: 0
    property int tried: 0
    readonly property int status: image.status
    readonly property bool ready: image.status === Image.Ready
    readonly property bool failed: image.status === Image.Error
    readonly property bool showPlaceholder: root.source === "" || root.failed || !root.everReady

    onReadyChanged: if (ready) everReady = true
    onSourceChanged: tried = 0
    onFailedChanged: if (failed && tried < retries) retry.restart()

    function reload() {
        image.source = ""
        image.source = Qt.binding(() => root.source)
    }

    Timer {
        id: retry
        interval: Theme.imageRetry
        onTriggered: {
            root.tried++
            root.reload()
        }
    }

    Image {
        id: image
        anchors.fill: parent
        source: root.source
        asynchronous: true
        cache: true
        mipmap: root.mipmap
        smooth: root.smooth
        fillMode: root.fillMode
        sourceSize: root.sourceSize.width > 0 && root.sourceSize.height > 0 ? root.sourceSize : undefined
        visible: root.source !== "" && root.status !== Image.Error
        //@ if hasQtVersion(6, 8)
        retainWhileLoading: root.retain
        //@ endif
    }
}
