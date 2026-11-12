import QtQuick

Item {
    id: root
    property font targetFont
    property string text: ""
    visible: false

    FontMetrics {
        id: fm
        font: root.targetFont
    }

    TextMetrics {
        id: tm
        font: root.targetFont
        text: root.text
    }

    readonly property real shift: Math.round((fm.descent - fm.ascent) / 2 - (tm.tightBoundingRect.y + tm.tightBoundingRect.height / 2))
}
