import QtQuick
import QtQuick.Shapes

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
    property bool opaque: false
    property real radius: 0
    readonly property Image face: flip ? second : first
    readonly property Image under: flip ? first : second
    readonly property int status: face.status
    readonly property bool ready: face.status === Image.Ready
    readonly property bool failed: face.status === Image.Error
    readonly property bool blank: String(root.source) === ""
    readonly property bool loading: face.status === Image.Loading
    readonly property bool held: under.opacity > 0
    readonly property real coverage: Math.max(face.status === Image.Ready ? face.opacity : 0, under.status === Image.Ready ? under.opacity : 0)
    readonly property bool soft: opaque && fade > 0
    readonly property bool rounded: radius > 0
    readonly property bool showPlaceholder: root.blank || ((root.failed || !root.everReady) && !root.held)

    onSourceChanged: {
        tried = 0
        apply()
    }

    onReadyChanged: if (ready) {
        everReady = true
        if (held || face.opacity < 1)
            cross.restart()
    }

    onFailedChanged: {
        if (failed && tried < retries)
            retry.restart()
        else if (failed && soft && held)
            fadeOut(under)
    }

    Component.onCompleted: apply()

    function apply() {
        const cur = root.face
        const other = root.under
        const empty = String(root.source) === ""
        cross.stop()
        if (drop.running)
            drop.complete()
        if (root.fade > 0 && !empty && cur.status !== Image.Ready && other.opacity > 0 && other.status === Image.Ready) {
            cur.source = root.source
            return
        }
        if (root.fade > 0 && !empty && cur.status === Image.Ready) {
            cur.opacity = 1
            cur.z = 0
            other.opacity = 0
            other.z = 1
            other.source = root.source
            root.flip = !root.flip
            return
        }
        if (root.soft && empty && cur.status === Image.Ready && cur.opacity > 0) {
            other.opacity = 0
            other.source = ""
            fadeOut(cur)
            return
        }
        cur.opacity = root.soft && !empty ? 0 : 1
        cur.z = 1
        cur.source = root.source
        other.opacity = 0
        other.source = ""
    }

    function drawn(img) {
        return img.opacity > 0 && String(img.source) !== "" && img.status !== Image.Error
    }

    function reload() {
        root.face.source = ""
        root.face.source = root.source
    }

    function fadeOut(img) {
        drop.target = img
        drop.restart()
    }

    NumberAnimation {
        id: drop
        property: "opacity"
        to: 0
        duration: root.fade
        easing.type: Theme.ease
        onStopped: if (target && target.opacity === 0) target.source = ""
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

        SequentialAnimation {
            PauseAnimation {
                duration: root.opaque ? root.fade : 0
            }

            NumberAnimation {
                target: root.under
                property: "opacity"
                to: 0
                duration: root.opaque ? 0 : root.fade
                easing.type: Theme.ease
            }
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
        visible: !root.rounded && root.drawn(first)
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
        visible: !root.rounded && root.drawn(second)
        //@ if hasQtVersion(6, 8)
        retainWhileLoading: root.retain
        //@ endif
    }

    Loader {
        anchors.fill: parent
        active: root.rounded
        sourceComponent: Item {
            Fill { img: first }
            Fill { img: second }
        }
    }

    component Fill: Shape {
        required property Image img
        readonly property real sx: img.implicitWidth > 0 ? img.paintedWidth / img.implicitWidth : 1
        readonly property real sy: img.implicitHeight > 0 ? img.paintedHeight / img.implicitHeight : 1
        width: root.width
        height: root.height
        z: img.z
        opacity: img.opacity
        visible: root.drawn(img) && img.implicitWidth > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: "transparent"
            fillItem: img
            fillTransform: PlanarTransform.fromAffineMatrix(sx, 0, 0, sy, (root.width - img.paintedWidth) / 2, (root.height - img.paintedHeight) / 2)

            PathRectangle {
                width: root.width
                height: root.height
                radius: root.radius
            }
        }
    }
}
