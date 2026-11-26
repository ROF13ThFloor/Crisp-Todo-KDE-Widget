import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.5 as Kirigami

Kirigami.FormLayout {
    property alias cfg_title: titleField.text
    property alias cfg_sinkCompleted: sinkBox.checked
    property alias cfg_newOnTop: topBox.checked
    property alias cfg_showBadge: badgeBox.checked

    QQC2.TextField {
        id: titleField
        Kirigami.FormData.label: i18n("Title:")
        placeholderText: i18n("My Tasks")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.CheckBox {
        id: sinkBox
        Kirigami.FormData.label: i18n("Behavior:")
        text: i18n("Move completed tasks to the bottom")
    }

    QQC2.CheckBox {
        id: topBox
        text: i18n("Add new tasks at the top of the list")
    }

    QQC2.CheckBox {
        id: badgeBox
        Kirigami.FormData.label: i18n("Panel icon:")
        text: i18n("Show number of remaining tasks")
    }
}
