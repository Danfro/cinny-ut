import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Suru 2.2
import Lomiri.Components 1.3 as UITK

UITK.LomiriShape {

    id: flyingBackButtonItem
    signal clicked()
    property var bgColor: theme.palette.highlighted.foreground
    property bool hideable

    anchors.right: parent.right
    anchors.margins: width / 2
    anchors.verticalCenter: parent.verticalCenter

    width: units.gu(4)
    height: width * 1.5
    backgroundColor: bgColor
    aspect: UITK.LomiriShape.DropShadow
    // radius: "small"
    relativeRadius: 1
    opacity: 0.9
    visible: false // this way allow it to only show up when whe really want to show it

    z: 14
    MouseArea {
        id: mouseArea
        property int startXPos: 0
        property int startYPos: 0
        property int diffPos: 0

        anchors.fill: parent
        enabled: parent.visible

        onPressed: {
            parent.backgroundColor = Qt.darker(bgColor, 1.3)
            //register x and y position when tapped/clicked
            startXPos = mouse.x
            startYPos = mouse.y
        }
        onReleased: parent.backgroundColor = bgColor
        onClicked: parent.clicked()
        onPositionChanged: {
            diffPos = Math.max(Math.abs(mouse.x - startXPos),Math.abs(mouse.y - startYPos))
            //if moved more than the set distance in any direction, trigger the action
            if (diffPos > 70  && hideable) {
                flyingBackButtonItem.visible = false
            }
        }
    }
    UITK.Icon {
        name: "toolkit_chevron-rtl_3gu"
        width: units.gu(3.5)
        height: width
        anchors.topMargin: height / 2
        anchors.centerIn: parent
        color: theme.palette.normal.baseText
    }
}
