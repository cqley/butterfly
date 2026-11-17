import QtQuick

Item {
    property alias text: label.text

    width: parent ? parent.width : 0
    height: label.implicitHeight + Theme.emptyPad

    Txt {
        id: label
        anchors.centerIn: parent
        opacity: Theme.dimEmpty
    }
}
