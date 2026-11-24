import "../core"
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property real t: 1
    property bool async: true
    readonly property size size: Theme.shellScreens.length ? Qt.size(Theme.shellScreens[0].width, Theme.shellScreens[0].height) : Qt.size(root.width, root.height)
    readonly property string path: Theme.pal && Theme.pal.wallpaper ? String(Theme.pal.wallpaper) : ""
    readonly property bool ready: wall.status === Image.Ready && source.status === Image.Ready
    readonly property Item glass: blurred

    anchors.fill: parent

    Item {
        anchors.fill: parent
        opacity: root.t

        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            visible: !root.ready
        }

        Image {
            id: wall
            anchors.fill: parent
            source: Theme.url(root.path)
            sourceSize: root.size
            fillMode: Image.PreserveAspectCrop
            asynchronous: root.async
            cache: true
            smooth: true
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: Theme.lockerDim
            visible: Theme.lockerDim > 0
        }
    }

    Image {
        id: source
        width: root.width / Theme.lockerGlassScale
        height: root.height / Theme.lockerGlassScale
        visible: false
        source: Theme.url(root.path)
        sourceSize: Qt.size(root.size.width / Theme.lockerGlassScale, root.size.height / Theme.lockerGlassScale)
        fillMode: Image.PreserveAspectCrop
        asynchronous: root.async
        cache: true
        smooth: true
    }

    MultiEffect {
        id: blurred
        readonly property bool ready: root.ready
        width: source.width
        height: source.height
        scale: Theme.lockerGlassScale
        transformOrigin: Item.TopLeft
        source: source
        autoPaddingEnabled: false
        blurEnabled: true
        blur: Theme.lockerGlassBlur
        blurMax: Theme.lockerGlassBlurMax
        blurMultiplier: Theme.lockerGlassBlurMul
        brightness: Theme.lockerGlassBright
        saturation: Theme.lockerGlassSat
    }
}
