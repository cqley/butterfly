import QtQuick

Item {
    id: root
    property real response: Theme.springResponse
    property real damping: Theme.springDamping
    property real epsilon: Theme.springEps
    property real rest: Theme.springStop
    property real target: 0
    property real value: 0
    property real velocity: 0
    property real hold: 0
    property real origin: 0
    readonly property bool moving: drive.running
    property real shaped: 0

    function shape() {
        const s = root.target - root.origin
        if (root.hold <= 0 || Math.abs(s) < 1e-6)
            return root.value
        return root.origin + s * Math.min(1, Math.max(0, (root.value - root.origin) / s) / (1 - root.hold))
    }

    function land(v) {
        drive.stop()
        root.velocity = 0
        root.value = v
        root.origin = v
        root.shaped = v
    }

    function kick(v) {
        root.velocity += v
        drive.start()
    }

    function step(dt) {
        const w = 2 * Math.PI / Math.max(root.response, 0.001)
        const z = Math.max(root.damping, 0.001)
        const decay = Math.exp(-z * w * dt)
        let x = root.value - root.target
        let v = root.velocity
        if (Math.abs(z - 1) < 0.001) {
            const c = v + w * x
            x = (x + c * dt) * decay
            v = (v - w * dt * c) * decay
        } else if (z < 1) {
            const d = w * Math.sqrt(1 - z * z)
            const c = (v + z * w * x) / d
            const cs = Math.cos(d * dt)
            const sn = Math.sin(d * dt)
            const nx = decay * (x * cs + c * sn)
            v = decay * (v * cs - (w * w * x + z * w * v) / d * sn)
            x = nx
        } else {
            const s = w * Math.sqrt(z * z - 1)
            const r1 = -z * w + s
            const r2 = -z * w - s
            const c1 = (v - r2 * x) / (r1 - r2)
            const c2 = x - c1
            const e1 = Math.exp(r1 * dt)
            const e2 = Math.exp(r2 * dt)
            x = c1 * e1 + c2 * e2
            v = c1 * r1 * e1 + c2 * r2 * e2
        }
        if (Math.abs(x) < root.epsilon && Math.abs(v) < root.rest) {
            root.land(root.target)
            return
        }
        root.value = root.target + x
        root.velocity = v
        root.shaped = root.shape()
    }

    onTargetChanged: {
        if (root.hold > 0)
            root.value = root.shaped
        root.origin = root.value
        root.shaped = root.value
        drive.start()
    }

    Component.onCompleted: root.land(root.target)

    FrameAnimation {
        id: drive
        running: false
        onTriggered: root.step(Math.min(frameTime, Theme.springMaxFrame))
    }
}
