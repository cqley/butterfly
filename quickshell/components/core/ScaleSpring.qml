import QtQuick

Spring {
    property real size: 0

    response: Theme.feedbackResponse
    epsilon: Theme.springUnitEps
    rest: Theme.springUnitStop
    settle: Theme.scaleSettle(size)
}
