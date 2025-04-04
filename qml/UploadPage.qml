/*
 * Copyright (C) 2016 Stefano Verzegnassi
 * Copyright (C) 2025  Danfro
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License 3 as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see http://www.gnu.org/licenses/.
 */

import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Content 1.3
import Backend 1.0



Page {
    id: picker
    property var activeTransfer

    property var url
    property var handler
    property var contentType

    signal cancel()
    signal imported(string fileUrl)
    signal rejected()

    header: PageHeader{
        title: i18n.tr("Chose")
        leadingActionBar.actions:[
            Action {
                id: backAction
                iconName: "back"
                text: i18n.tr('Back')
                onTriggered:{
                    Backend.removeDownload(url)
                    rejected()
                    pageStack.pop()

                }
            }
        ]
    }

    ContentPeerPicker {
        anchors { fill: parent; topMargin: picker.header.height }
        visible: parent.visible
        showTitle: false
        contentType: picker.contentType
        handler: picker.handler //ContentHandler.Source

        onPeerSelected: {
            picker.activeTransfer = peer.request()
            picker.activeTransfer.stateChanged.connect(function() {
                        if (picker.activeTransfer.state === ContentTransfer.InProgress) {
                               picker.activeTransfer.items = picker.activeTransfer.items[0].url = url;
                               picker.activeTransfer.state = ContentTransfer.Charged;
                        }
                if (picker.activeTransfer.state === ContentTransfer.Charged) {
                    picker.imported(picker.activeTransfer.items[0].url)
                    picker.activeTransfer = null
                    pageStack.pop()
                }
            })
        }


        onCancelPressed: {
            rejected()
            pageStack.pop()
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: picker.activeTransfer
    }
    Component {
        id: resultComponent
        ContentItem {}
    }
}
