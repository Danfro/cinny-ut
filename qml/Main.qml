/*
 * Copyright (C) 2022  Marcel Alexandru Nitan
 * Copyright (C) 2025  Danfro
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
import QtQuick.Controls 2.12
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
    applicationName : 'cinny.danfro'
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
        property string systemTheme: '' // empty means use system theme
        property string pushToken: ''
        property string pushAppId: 'cinny.danfro_cinny'
        property bool windowActive: true
        property bool bottomBarIsActive: true
        property bool visualHintIsActive: true
    }

    Arguments {
        id: args;
        //TRANSLATORS: %1 does specify the parameters, %2 does specify the url for weather apps repo at gitlab
        // defaultArgument.help: i18n.tr("Valid arguments for weather app are: %1 They will be managed by system. See the README at %2 for a full comment about them").arg("--location, --city, --lat, --lng").arg("https://gitlab.com/ubports/development/apps/lomiri-weather-app/");
        defaultArgument.valueNames: []
    }

    Component.onCompleted: function () {
        theme.name = ""
        appSettings.systemTheme = theme.name.substring(theme.name.lastIndexOf(".")+1)

        serverCheckTimer.start()
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
    }
    Page {
        id : mainPage
        anchors.fill : parent

        // bg
        Rectangle {
            color: theme.palette.normal.background
            anchors.fill: parent
        }

        WebEngineView {
            id : webView
            anchors.fill : parent
            anchors.bottomMargin: bottomGesture.enableVisualHint ? bottomGesture.gestureAreaHeight : 0
            focus : true
            // url: will be set in serverCheckTimer to avoid race condition when HTTP-server is not ready but component is created
            webChannel: channel
            settings.pluginsEnabled : true
            settings.javascriptEnabled : true
            profile : webContext

            onNewViewRequested : function (request) {
                request.action = WebEngineNavigationRequest.IgnoreRequest
                if (request.requestedUrl !== "ignore://") {
                    // console.log("requested url: " + request.requestedUrl.toString())
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

        BottomNavigationGesture {
            id: bottomGesture
            enabled: appSettings.bottomBarIsActive

            webview: webView
            anchors.fill: parent
        }

        Connections {
            target: UriHandler

            onOpened: {
                // depending on where the app is, local urls differ, examples:
                // http://localhost:19999/direct/
                // http://localhost:19999/home/
                // I don't know how to determine from the uri if the chat is direct, home or other
                // so always go to root page, then a window opens and offers to view the chat
                let result = uris[0].toString().replace("cinny://", "http://localhost:19999/")
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
            property var push: null

            signal matrixPushTokenChanged();

            function setTheme(themeName) {
                setCurrentTheme(themeName)
            }

            function toggleBottomBar(value) {
                bottomGesture.enabled = value
                appSettings.bottomBarIsActive = value
            }

            function toggleDisplayHint(value) {
                bottomGesture.enableVisualHint = value
                appSettings.visualHintIsActive = value
            }
        }
        WebEngineProfile {
            id : webContext
            property var filePath
            property var contentType
            storageName : "Storage"
            persistentStoragePath : appDataPath + "/QWebEngine"
            // set default downloadpath because typescript webdownload always saves to this folder
            downloadPath: appCachePath  // downloads are saved only temporary and forwarded by content hub to the target location
            cachePath: appCachePath
            onDownloadRequested: function (downloadItem) {
                // https://doc.qt.io/qt-5/qml-qtwebengine-webenginedownloaditem.html

                // determine content hub type based on mime type
                // TODO: add more mime types, see dekko and here: https://developer.mozilla.org/en-US/docs/Web/HTTP/MIME_types/Common_types
                var timestamp = new Date
                var audioBaseName = "Cinny soundfile " + Qt.formatDateTime(new Date(),"yyyy-MM-dd_hh-mm-ss")
                switch (downloadItem.mimeType) {
                    case "image/jpeg": // no break between this and the next condition means both are treated the same
                    case "image/png":
                    case "image/gif":
                    case "image/bmp":
                    case "image/webp":
                    case "image/svg":
                    case "image/svg+xml":
                        contentType = ContentType.Pictures; //int 2
                        break
                    // audio items currently do not provide a file name, just the internal url -> assign a default file name
                    case "audio/mpeg":
                        contentType = ContentType.Music; //int 3
                        console.log("audio file name: " + downloadItem.downloadFileName)
                        // 
                        downloadItem.downloadFileName = audioBaseName + ".mp3"
                        console.log("audio file name: " + downloadItem.downloadFileName)
                        break;
                    case "audio/ogg":
                        contentType = ContentType.Music; //int 3
                        console.log("audio file name: " + downloadItem.downloadFileName)
                        // 
                        downloadItem.downloadFileName = audioBaseName + ".ogg"
                        console.log("audio file name: " + downloadItem.downloadFileName)
                        break;
                    case "audio/ogg":
                        contentType = ContentType.Music; //int 3
                        console.log("audio file name: " + downloadItem.downloadFileName)
                        // 
                        downloadItem.downloadFileName = "Cinny soundfile.ogg"
                        console.log("audio file name: " + downloadItem.downloadFileName)
                        break;
                    case "video/mp4":
                    case "video/mpeg":
                    case "video/h264":
                        // contentType = ContentType.Video; //not defined -> use type all
                        contentType = ContentType.All; //int -1
                        break;
                    case "text/vcard": //.vcf
                    case "text/x-vcard": //.vcf
                        contentType = ContentType.Contacts; //int 4
                        break;
                    case "text/plain":
                    case "text/richtext":
                    case "text/markdown":
                    case "application/pdf":
                        contentType = ContentType.Documents; //int 1
                        break;
                    case "application/epub+zip":
                        contentType = ContentType.Ebooks; //int ?
                        console.log("CH type for ebook: " + ContentType.Ebooks)
                        break;
                    default:
                        contentType = ContentType.All; //int -1
                        console.log("content hub type default used for item of mime type " + downloadItem.mimeType);
                }

                filePath = downloadItem.downloadDirectory + "/" + downloadItem.downloadFileName
                downloadItem.accept()
                // wait until download is finished before processing the next command
                while(downloadItem.state != 1) {
                    wait(100)
                }
                mainPageStack.push(Qt.resolvedUrl("DownloadPage.qml"), {
                    "url": filePath, 
                    "itemContentType": contentType, 
                    "exportHandler": ContentHandler.Destination
                    }
                )
            }
            // js waiter function
            function wait(ms){
                var start = new Date().getTime();
                var end = start;
                while(end < start + ms) {
                    end = new Date().getTime();
                }
            }
        }
    }

    Timer {
        id: serverCheckTimer
        interval: 200  // wait some ms to ensure HTTP-Server is ready before loading components in mainPage and setting url
        repeat: false
        onTriggered: {
            mainPageStack.push(mainPage)

            // check if HTTP-server is available
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "http://localhost:19999/", true);
            xhr.onload = function() {
                if (xhr.status === 200) {
                    // server is ready, load Cinny
                    webView.url = args.defaultArgument.at(0) ? 
                        args.defaultArgument.at(0).toString().replace("cinny://", "http://localhost:19999/") : 
                        "http://localhost:19999/";
                    serverCheckTimer.stop();
                } else {
                    console.log("local HTTP-server not ready yet, status: " + xhr.status);
                }
            };
            xhr.onerror = function() {
                console.log("Error when checking for HTTP-server.");
            };
            xhr.send();
        }
    }

    Loader {
        id: pushClientLoader
        active: false
        sourceComponent: Component {
            PushClient {
                id: pushClient
                appId: appSettings.pushAppId

                onTokenChanged: {
                    appSettings.pushToken = token
                    webChannelObject.matrixPushTokenChanged();
                }

                Component.onCompleted: webChannelObject.push = pushClient
            }
        }
    }
}
