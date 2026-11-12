import QtQuick

Fade {
    property real pad: 0
    property real padX: pad
    property real padBottom: pad
    property real wantW: width + 2 * padX
    property real wantH: y + height + padBottom

    y: pad
}
