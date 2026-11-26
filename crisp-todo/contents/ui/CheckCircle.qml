import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore

// Round, animated checkbox.
Item {
    id: box

    property bool checked: false
    signal toggled()

    implicitWidth: Math.round(PlasmaCore.Units.gridUnit * 1.15)
    implicitHeight: implicitWidth

    readonly property color hl: PlasmaCore.Theme.highlightColor
    readonly property color tc: PlasmaCore.Theme.textColor
    readonly property color onHl: PlasmaCore.Theme.highlightedTextColor
    readonly property bool preview: mouse.containsMouse && !checked

    property real progress: checked ? 1 : 0
    Behavior on progress {
        NumberAnimation { duration: PlasmaCore.Units.longDuration; easing.type: Easing.OutCubic }
    }

    onProgressChanged: mark.requestPaint()
    onPreviewChanged: mark.requestPaint()
    onHlChanged: mark.requestPaint()
    onOnHlChanged: mark.requestPaint()

    Rectangle {
        id: circle
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(box.hl.r, box.hl.g, box.hl.b, box.progress)
        border.width: Math.max(1.5, width * 0.09)
        border.color: (mouse.containsMouse || box.checked)
                      ? box.hl
                      : Qt.rgba(box.tc.r, box.tc.g, box.tc.b, 0.4)
        scale: mouse.pressed ? 0.85 : 1
        Behavior on scale { NumberAnimation { duration: PlasmaCore.Units.shortDuration } }
        Behavior on border.color { ColorAnimation { duration: PlasmaCore.Units.shortDuration } }
    }

    Canvas {
        id: mark
        anchors.fill: parent
        scale: circle.scale
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w = width, h = height
            var p0 = { x: w * 0.29, y: h * 0.52 }
            var p1 = { x: w * 0.44, y: h * 0.67 }
            var p2 = { x: w * 0.72, y: h * 0.36 }

            var amount = box.progress
            var color = box.onHl
            if (amount <= 0.001) {
                if (!box.preview)
                    return
                amount = 1
                color = Qt.rgba(box.hl.r, box.hl.g, box.hl.b, 0.55)
            }

            var l1 = Math.hypot(p1.x - p0.x, p1.y - p0.y)
            var l2 = Math.hypot(p2.x - p1.x, p2.y - p1.y)
            var d = amount * (l1 + l2)

            ctx.lineWidth = Math.max(1.5, w * 0.11)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.strokeStyle = color
            ctx.beginPath()
            ctx.moveTo(p0.x, p0.y)
            if (d <= l1) {
                var t = d / l1
                ctx.lineTo(p0.x + (p1.x - p0.x) * t, p0.y + (p1.y - p0.y) * t)
            } else {
                ctx.lineTo(p1.x, p1.y)
                var t2 = (d - l1) / l2
                ctx.lineTo(p1.x + (p2.x - p1.x) * t2, p1.y + (p2.y - p1.y) * t2)
            }
            ctx.stroke()
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -PlasmaCore.Units.smallSpacing
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: box.toggled()
    }
}
