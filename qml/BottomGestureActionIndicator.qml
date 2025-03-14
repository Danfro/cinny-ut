import QtQuick 2.9
import Lomiri.Components 1.3
import QtGraphicalEffects 1.12

Item {
    id: root

    readonly property bool readyToTrigger: scale >= maxScale
    property real defaultWidth: units.gu(5)
    property real defaultScale: 1
    property real maxScale: 1.5

    property alias iconName: iconItem.name
    property real swipeProgress
    property bool enabled: true
    property bool heldState: false
    property color defaultColor: theme.palette.normal.foreground
    property color highlightedColor: theme.palette.highlighted.foreground
    property color iconColor: theme.palette.normal.foregroundText
    property color shadowColor: theme.palette.normal.foregroundText
    property color heldColor: theme.palette.normal.activity

    visible: opacity > 0
    opacity: 0
    width: defaultWidth
    height: width
    scale: defaultScale

    function show() {
        state = "shown"
    }

    function hide() {
        state = "hidden"
        heldState = false
    }

    function delayedHide() {
        delayedHideTimer.restart()
    }

    Timer {
        id: delayedHideTimer
        running: false
        interval: 400
        onTriggered: root.hide()
    }

    Behavior on scale {
        LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration}
    }

    Behavior on opacity {
        LomiriNumberAnimation { duration: LomiriAnimation.BriskDuration }
    }

    state: "hidden"
    states: [
        State {
            name: "shown"

            PropertyChanges {
                target: root
                scale: root.defaultScale + ((root.maxScale - root.defaultScale) * root.swipeProgress)
                opacity: enabled ? 1 : 0.2
            }
        }
        , State {
            name: "hidden"

            PropertyChanges {
                target: root
                scale: root.defaultScale
                opacity: 0
            }
        }
    ]

    Rectangle {
        id: bg

        anchors.fill: parent
        radius: width / 2
        color: heldState ? heldColor : readyToTrigger ? highlightedColor : defaultColor

        border {
            width: units.dp(1)
            color: theme.palette.normal.base
        }

        Behavior on color {
            ColorAnimation {
                duration: LomiriAnimation.FastDuration
            }
        }

        Icon {
            id: iconItem

            anchors.centerIn: parent
            height: parent.height * 0.5
            width: height
            color: root.iconColor
        }
    }
}
