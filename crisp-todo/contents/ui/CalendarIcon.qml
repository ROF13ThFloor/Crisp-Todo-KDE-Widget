import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore

// A small calendar glyph drawn in QML, so it looks the same with every
// icon theme.
Item {
    id: glyph

    property color color: PlasmaCore.Theme.textColor
    readonly property real stroke: Math.max(1.5, Math.round(width / 11))

    implicitWidth: PlasmaCore.Units.iconSizes.small
    implicitHeight: implicitWidth

    // Page
    Rectangle {
        id: page
        anchors.fill: parent
        anchors.topMargin: Math.round(glyph.height * 0.14)
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        radius: Math.max(2, glyph.width * 0.16)
        color: "transparent"
        border.width: glyph.stroke
        border.color: glyph.color
    }

    // Header bar
    Rectangle {
        x: page.x
        y: page.y
        width: page.width
        height: Math.round(page.height * 0.3)
        radius: page.radius
        color: glyph.color
    }

    // Binder rings
    Repeater {
        model: 2
        Rectangle {
            width: glyph.stroke
            height: Math.round(glyph.height * 0.24)
            radius: width / 2
            x: Math.round(glyph.width * (index === 0 ? 0.3 : 0.7) - width / 2)
            y: 0
            color: glyph.color
        }
    }

    // A "day" dot
    Rectangle {
        width: Math.max(2, Math.round(glyph.width * 0.18))
        height: width
        radius: 1
        x: Math.round(page.x + page.width * 0.62 - width / 2)
        y: Math.round(page.y + page.height * 0.62 - height / 2)
        color: glyph.color
    }
}
