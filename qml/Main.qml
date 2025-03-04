/*
 * Copyright (C) 2022  Marcel Alexandru Nitan
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * cinny is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.PushNotifications 0.1
import Lomiri.Content 1.3
import Lomiri.DownloadManager 1.2
import QtQuick.Window 2.12
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtQml 2.12
import QtWebEngine 1.11
import QtWebChannel 1.0
import Backend 1.0
import Qt.labs.platform 1.0 as PF //for StandardPaths

// Comment

MainView {
    id : mainView
    objectName : 'mainView'
    applicationName : 'cinny.nitanmarcel'
    automaticOrientation : true
    backgroundColor : "transparent"
    anchors {
        fill : parent
        bottomMargin : LomiriApplication.inputMethod.visible
            ? LomiriApplication
                .inputMethod
                .keyboardRectangle
                .height / Screen.devicePixelRatio
            : 0
        Behavior on bottomMargin {
            NumberAnimation {
                duration : 175
                easing.type : Easing.OutQuad
            }
        }
    }

    property string appDataPath: PF.StandardPaths.writableLocation(PF.StandardPaths.AppDataLocation).toString().replace("file://","")
    property string appCachePath: PF.StandardPaths.writableLocation(PF.StandardPaths.CacheLocation).toString().replace("file://","")

    Settings {
        id: appSettings
        property string systemTheme: 'Ambiance'
        property string pushToken: ''
        property string pushAppId: 'cinny.nitanmarcel_cinny'
        property bool windowActive: true
    }

    Component.onCompleted: function () {
        theme.name = ""
        appSettings.systemTheme = theme.name.substring(theme.name.lastIndexOf(".")+1)
    }
    onActiveChanged: () => {appSettings.windowActive = mainView.active}

    function setCurrentTheme(themeName) {
            if (themeName === "System") {
              theme.name = "";
            }
            else if (themeName === "SuruDark") {
                theme.name = "Lomiri.Components.Themes.SuruDark"
            }
            else if (themeName === "Ambiance") {
                theme.name = "Lomiri.Components.Themes.Ambiance"
            }
            else {
              theme.name = "";
            }
        }

    PageStack {
        id : mainPageStack
        anchors.fill : parent
        Component.onCompleted : mainPageStack.push(mainPage)
        Page {
            id : mainPage
            anchors.fill : parent
            WebEngineView {
                id : webView
                anchors.fill : parent
                focus : true
                url : "http://localhost:19999/"
                webChannel: channel
                settings.pluginsEnabled : true
                settings.javascriptEnabled : true
                profile : WebEngineProfile {
                    id : webContext
                    storageName : "Storage"
                    persistentStoragePath : appDataPath + "/QWebEngine"
                    // set default downloadpath because typescript webdownload always saves to this folder
                    downloadPath: appCachePath  // downloads are saved only temporary and forwarded by content hub to the target location
                    cachePath: appCachePath
                    onDownloadRequested: function (download) {
                         download.accept()
                         console.log("onDownloadRequested triggered")
                    }

                }
                onNewViewRequested : function (request) {
                    request.action = WebEngineNavigationRequest.IgnoreRequest
                    if (request.requestedUrl !== "ignore://") {
                        Qt.openUrlExternally(request.requestedUrl)
                    }
                }
                onFileDialogRequested : function (request) {
                    request.accepted = true;
                    var uploadPage = mainPageStack.push(Qt.resolvedUrl("UploadPage.qml"), {"contentType": ContentType.All, "handler": ContentHandler.Source})
                    uploadPage.imported.connect(function (fileUrl) {
                        request.dialogAccept(fileUrl);
                    })
                    uploadPage.rejected.connect(function () {
                        request.dialogReject()
                    })
                }

                onFullScreenRequested : function (request) {
                    request.accept()
                    if (request.toggleOn)
                        window.showFullScreen()
                    else
                        window.showNormal()
                }

            }

            Connections {
                target: UriHandler

                onOpened: {
                    let result = uris[0].toString().replace("cinny://sso/", webView.url.toString())
                    webView.url = result
                  }
              }

            WebChannel {
                id: channel
                registeredObjects: [webChannelObject]
            }

            QtObject {
                id: webChannelObject
                WebChannel.id: "webChannelBackend"

                property alias settings: appSettings
                property alias push: pushClient

                signal matrixPushTokenChanged();

                function handleDownload(fileName,content) {
                    var filePath = appCachePath + "/" + fileName
                    var contentType
                    switch (content) {
                        case "image":
                            contentType = ContentType.Pictures; //int 2
                            console.log("content hub type image");
                            break;
                        case "audio":
                            contentType = ContentType.Music; //int 3
                            console.log("content hub type audio");
                            break;
                        // case "video":
                        //     contentType = ContentType.Video; //not defined
                        //     console.log("content hub type video");
                        //     break;
                        case "contact":
                            contentType = ContentType.Contacts; //int 4
                            console.log("content hub type contact");
                            break;
                        case "document":
                            contentType = ContentType.Documents; //int 1
                            console.log("content hub type document");
                            break;
                        case "default":
                            contentType = ContentType.All; //int -1
                            console.log("content hub type default");
                            break;
                        default:
                            contentType = ContentType.All; //int -1
                    }
                    mainPageStack.push(Qt.resolvedUrl("DownloadPage.qml"), {"url": filePath, "itemContentType": contentType, "handler": ContentHandler.Share})
                }

                function setTheme(themeName) {
                    setCurrentTheme(themeName)
                }
            }
        }
    }

    PushClient {
        id: pushClient
        appId: appSettings.pushAppId

        onTokenChanged: {
            appSettings.pushToken = token
            webChannelObject.matrixPushTokenChanged();
        }
    }
}
