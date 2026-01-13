import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root
    
    // Data variables
    property string repoName: "github.com"
    property string updateTitle: "Waiting for data..."
    property string timeStamp: ""

    // Listen for lines from stdin
    // You can send data via: echo '{"title": "...", ...}' > /proc/<pid>/fd/0
    // or by piping tail -f into quickshell.
    Connections {
        target: Quickshell.stdin
        function onLine(data) {
            try {
                for (var thing of JSON.parse(data)){
                // thing?.title??="No Title"
                // thing?.url??="no url"
                updateTitle = thing.title
                
                // Handling date
                let rawDate = thing?.updated_at || "";
                timeStamp = rawDate ? "Updated " + rawDate.split('T')[0] : "recently";
                
                // Extracting repo from URL
                let url = (thing.url) ? thing.url : (thing.url || "");
                }
            } catch (e) {
                console.log("Error parsing incoming data: " + e);
            }
        }
    }

    PanelWindow {
        id: win
        
        implicitWidth: 412
        implicitHeight: mainLayout.implicitHeight
        
        anchors {
            top: true
            right: true
        }

        Rectangle {
            id: mainLayout
            anchors.fill: parent
            implicitHeight: 100 
            color: "#121212"
            border.color: "#333333"
            border.width: 1

            Column {
                anchors.fill: parent
                spacing: 0

                // Header Bar (22px)
                Rectangle {
                    width: parent.width
                    height: 22
                    color: "#a38b8b"
                    
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "GitHub Notifications"
                        color: "white"
                        font.family: "Monospace"
                        font.pixelSize: 11
                        font.bold: true
                        renderType: Text.NativeRendering
                    }
                }

                // Notification Body (56px)
                Item {
                    width: parent.width
                    height: 56
                    anchors.leftMargin: 10

                    // Text Content
                    Column {
                        anchors.left: iconBox.right
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        
                        Text {
                            text: updateTitle
                            color: "#ebc08d"
                            font.family: "Monospace"
                            font.pixelSize: 15
                            font.bold: true
                            width: 340
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }
                        
                        Text {
                            text: "Release · " + repoName + " · " + timeStamp
                            color: "#d1a77b"
                            font.family: "Monospace"
                            font.pixelSize: 12
                            renderType: Text.NativeRendering
                        }
                    }
                }

                // Footer Bar (22px)
                Rectangle {
                    width: parent.width
                    height: 22
                    color: "#a38b8b"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Sync Active"
                        color: "#e0e0e0"
                        font.family: "Monospace"
                        font.pixelSize: 11
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Close"
                        color: closeArea.containsMouse ? "white" : "#e0e0e0"
                        font.family: "Monospace"
                        font.pixelSize: 11
                        renderType: Text.NativeRendering

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.quit()
                        }
                    }
                }
            }
        }
    }
}