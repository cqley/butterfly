import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    default property alias content: slot.data
    property string label: ""
    property string value: ""
    property string note: ""
    property string token: ""
    property bool showArrow: false
    property bool last: true
    property bool interactive: showArrow
    readonly property bool modified: root.token !== "" && Cfg.has(root.token)
    signal activated

    function reset() {
        if (root.token !== "")
            Cfg.clear(root.token)
    }

    width: parent ? parent.width : 0
    height: Theme.settingsRowH + (root.note !== "" ? Theme.settingsNoteH : 0)

    Keys.onPressed: e => {
        Settings.keyNav = true
        if (root.modified && (e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace)) {
            root.reset()
            e.accepted = true
        }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: Theme.settingsRowPadX
        anchors.right: dot.left
        anchors.rightMargin: Theme.settingsModGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.settingsNoteDrop

        Txt {
            width: parent.width
            text: root.label
            font.pixelSize: Theme.settingsLabelPx
            font.weight: Font.Medium
            color: Theme.fg
            elide: Text.ElideRight
        }

        Txt {
            visible: root.note !== ""
            width: parent.width
            text: root.note
            font.pixelSize: Theme.settingsNotePx
            font.weight: Font.Normal
            color: Theme.settingsNoteInk
            elide: Text.ElideRight
        }
    }

    Item {
        id: dot
        width: root.modified ? Theme.settingsModHit : 0
        height: Theme.settingsModHit
        anchors.right: slot.left
        anchors.rightMargin: root.modified ? Theme.settingsModGap : 0
        anchors.verticalCenter: parent.verticalCenter
        visible: root.modified

        Rectangle {
            anchors.centerIn: parent
            width: Theme.settingsModDot
            height: Theme.settingsModDot
            radius: width / 2
            color: Theme.accent
            antialiasing: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.reset()
        }
    }

    Row {
        id: slot
        anchors.right: arrow.visible ? arrow.left : parent.right
        anchors.rightMargin: arrow.visible ? Theme.settingsValueGap : Theme.settingsRowPadX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.settingsValueGap

        Txt {
            visible: root.value !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.value
            font.pixelSize: Theme.settingsValuePx
            font.weight: Font.Normal
            color: Theme.settingsValueInk
        }
    }

    Item {
        id: arrow
        visible: root.showArrow
        width: Theme.settingsArrowSize
        height: Theme.settingsArrowSize
        x: Math.round(root.width - Theme.settingsRowPadX - width)
        y: Math.round((root.height - height) / 2)

        Shape {
            anchors.centerIn: parent
            width: Theme.iconGrid
            height: Theme.iconGrid
            scale: Theme.settingsArrowSize / Theme.iconGrid
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: Theme.glyphStroke(Theme.settingsArrowSize, Theme.settingsIconStroke)
                strokeColor: Theme.settingsArrowInk
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg { path: Theme.settingsArrowPath }
            }
        }
    }

    Rectangle {
        visible: !root.last
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.settingsRowPadX
        anchors.rightMargin: Theme.settingsRowPadX
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.settingsDivider
    }

    Item {
        id: hit
        anchors.fill: parent
        activeFocusOnTab: root.interactive
        visible: root.interactive

        Keys.onPressed: e => {
            Settings.keyNav = true
            if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                root.activated()
                e.accepted = true
            }
        }

        SettingsFocus {
            anchors.fill: parent
            anchors.margins: Theme.settingsFocusPad
            radius: Theme.settingsCardRadius
            focused: hit.activeFocus
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Settings.keyNav = false
                hit.forceActiveFocus()
                root.activated()
            }
        }
    }
}
