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
    property int fade: 0
    property bool flip: false
    readonly property Image face: flip ? second : first
    readonly property Image under: flip ? first : second
    readonly property int status: face.status
    readonly property bool ready: face.status === Image.Ready
    readonly property bool failed: face.status === Image.Error
    readonly property bool blank: String(root.source) === ""
    readonly property bool loading: face.status === Image.Loading
    readonly property bool held: under.opacity > 0
    readonly property bool showPlaceholder: root.blank || ((root.failed || !root.everReady) && !root.held)

    onSourceChanged: {
        tried = 0
        apply()
    }

    onReadyChanged: if (ready) {
        everReady = true
        if (held)
            cross.restart()
    }

    onFailedChanged: if (failed && tried < retries) retry.restart()

    Component.onCompleted: apply()

    function apply() {
        const cur = root.face
        const other = root.under
        const empty = String(root.source) === ""
        cross.stop()
        if (root.fade > 0 && !empty && cur.status === Image.Ready) {
            cur.opacity = 1
            cur.z = 0
            other.opacity = 0
            other.z = 1
            other.source = root.source
            root.flip = !root.flip
            return
        }
        cur.opacity = 1
        cur.z = 1
        cur.source = root.source
        other.opacity = 0
        other.source = ""
    }

    function reload() {
        root.face.source = ""
        root.face.source = root.source
    }

    ParallelAnimation {
        id: cross

        NumberAnimation {
            target: root.face
            property: "opacity"
            to: 1
            duration: root.fade
            easing.type: Theme.ease
        }

        NumberAnimation {
            target: root.under
            property: "opacity"
            to: 0
            duration: root.fade
            easing.type: Theme.ease
        }
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
        id: first
        anchors.fill: parent
        z: 1
        opacity: 1
        asynchronous: true
        cache: true
        mipmap: root.mipmap
        fillMode: root.fillMode
        sourceSize: root.sourceSize.width > 0 && root.sourceSize.height > 0 ? root.sourceSize : undefined
        visible: opacity > 0 && String(source) !== "" && status !== Image.Error
        //@ if hasQtVersion(6, 8)
        retainWhileLoading: root.retain
        //@ endif
    }

    Image {
        id: second
        anchors.fill: parent
        z: 0
        opacity: 0
        asynchronous: true
        cache: true
        mipmap: root.mipmap
        fillMode: root.fillMode
        sourceSize: root.sourceSize.width > 0 && root.sourceSize.height > 0 ? root.sourceSize : undefined
        visible: opacity > 0 && String(source) !== "" && status !== Image.Error
        //@ if hasQtVersion(6, 8)
        retainWhileLoading: root.retain
        //@ endif
    }
}
