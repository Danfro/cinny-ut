import QtQuick 2.4
import Lomiri.Components 1.3

Item {
    id: root

    property bool enableVisualHint: true
    property var webview
    property alias gestureAreaHeight: bottomBackForwardHandle.height

    BottomGestureActionIndicator {
        id: goForwardIcon

        iconName: "go-next"
        shadowColor: LomiriColors.ash
        swipeProgress: bottomBackForwardHandle.swipeProgress
        enabled: bottomBackForwardHandle.leftSwipeActionEnabled
        anchors {
            right: parent.right
            rightMargin: units.gu(3)
            verticalCenter: parent.verticalCenter
        }
    }

    BottomGestureActionIndicator {
        id: goBackIcon

        iconName: "go-previous"
        shadowColor: LomiriColors.ash
        swipeProgress: bottomBackForwardHandle.swipeProgress
        enabled: bottomBackForwardHandle.rightSwipeActionEnabled
        anchors {
            left: parent.left
            leftMargin: units.gu(3)
            verticalCenter: parent.verticalCenter
        }
    }

    HorizontalSwipeHandler {
        id: bottomBackForwardHandle
        objectName: "bottomBackForwardHandle"

        leftAction: goBackIcon
        rightAction: goForwardIcon
        immediateRecognition: true
        usePhysicalUnit: true
        height: units.gu(2)
        leftSwipeHoldEnabled: false
        rightSwipeHoldEnabled: false

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        leftSwipeActionEnabled: root.webview.canGoForward
        rightSwipeActionEnabled: root.webview.canGoBack
        onRightSwipe:  root.webview.goBack()
        onLeftSwipe:  root.webview.goForward()
        onPressedChanged: if (pressed) Haptics.play()
    }

    Rectangle {
        visible: root.enableVisualHint
        color: theme.palette.normal.backgroundSecondaryText
        anchors.centerIn: bottomBackForwardHandle
        width: Math.min(units.gu(15), bottomBackForwardHandle.width * 0.6)
        height: units.gu(0.5)
        radius: height / 2
    }
}
