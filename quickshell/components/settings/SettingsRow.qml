import "../core"
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    default property alias content: slot.data
    property string label: ""
    property string value: ""
    property string token: ""
    property bool showArrow: false
    property bool last: true
    property bool hasActor: false
    readonly property bool interactive: root.showArrow || root.hasActor
    readonly property bool modified: root.token !== "" && !Cfg.isDefault(root.token)
    signal activated

    function reset() {
        if (root.token !== "")
            Cfg.clear(root.token)
    }

    function actor() {
        const kids = slot.children
        for (let i = 0; i < kids.length; i++)
            if (typeof kids[i].rowActivate === "function")
                return kids[i]
        return null
    }

    function centerSlot() {
        const kids = slot.children
        for (let i = 0; i < kids.length; i++)
            kids[i].anchors.verticalCenter = slot.verticalCenter
    }

    function activate() {
        if (root.showArrow) {
            root.activated()
            return
        }
        const a = root.actor()
        if (a)
            a.rowActivate()
    }

    width: parent ? parent.width : 0
    height: Theme.settingsRowH

    Component.onCompleted: root.hasActor = root.actor() !== null

    Keys.onPressed: e => {
        Settings.keyNav = true
        if (root.modified && (e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace)) {
            root.reset()
            e.accepted = true
        }
    }

    Item {
        id: hit
        anchors.fill: parent
        activeFocusOnTab: true
        enabled: root.interactive
        visible: root.interactive

        Keys.onPressed: e => {
            Settings.keyNav = true
            if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                root.activate()
                e.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.settingsCardRadius
            color: Theme.settingsRowHover
            opacity: touch.containsMouse ? 1 : 0
            antialiasing: true

            Behavior on opacity {
                NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
            }
        }

        SettingsFocus {
            anchors.fill: parent
            anchors.margins: Theme.settingsFocusPad
            radius: Theme.settingsCardRadius
            focused: hit.activeFocus
        }

        MouseArea {
            id: touch
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Settings.keyNav = false
                hit.forceActiveFocus()
                root.activate()
            }
        }
    }

    Txt {
        anchors.left: parent.left
        anchors.leftMargin: Theme.settingsRowPadX
        anchors.right: dot.left
        anchors.rightMargin: Theme.settingsModGap
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.pixelSize: Theme.settingsLabelPx
        font.weight: Font.Medium
        color: Theme.settingsInk
        elide: Text.ElideRight
    }

    Item {
        id: dot
        width: root.token !== "" ? Theme.settingsModHit : 0
        height: Theme.settingsModHit
        anchors.right: slot.left
        anchors.rightMargin: root.token !== "" ? Theme.settingsModGap : 0
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.modified
        opacity: root.modified ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.feedbackDuration; easing.type: Theme.ease }
        }

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

        onChildrenChanged: root.centerSlot()
        Component.onCompleted: root.centerSlot()

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
        y: Theme.mid(root.height, height)

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
}
