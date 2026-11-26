import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: ring

    property real value: 0          // 0..1
    property real animatedValue: value
    Behavior on animatedValue {
        NumberAnimation { duration: PlasmaCore.Units.longDuration * 2; easing.type: Easing.OutCubic }
    }

    implicitWidth: Math.round(PlasmaCore.Units.gridUnit * 2.6)
    implicitHeight: implicitWidth

    readonly property color hl: PlasmaCore.Theme.highlightColor
    readonly property color tc: PlasmaCore.Theme.textColor

    onAnimatedValueChanged: canvas.requestPaint()
    onHlChanged: canvas.requestPaint()
    onTcChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var lw = Math.max(3, width * 0.1)
            var r = (Math.min(width, height) - lw) / 2
            var cx = width / 2, cy = height / 2

            ctx.lineWidth = lw
            ctx.lineCap = "round"

            ctx.strokeStyle = Qt.rgba(ring.tc.r, ring.tc.g, ring.tc.b, 0.12)
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.stroke()

            if (ring.animatedValue > 0.001) {
                ctx.strokeStyle = ring.hl
                ctx.beginPath()
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(1, ring.animatedValue))
                ctx.stroke()
            }
        }
    }

    PlasmaComponents3.Label {
        anchors.centerIn: parent
        text: Math.round(ring.value * 100) + "%"
        font.pixelSize: Math.round(ring.height * 0.26)
        font.bold: true
        opacity: 0.85
    }
}
