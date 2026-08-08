import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var taskList
    property string emptyPlaceholderIcon
    property string emptyPlaceholderText
    property int todoListItemSpacing: 5
    property int todoListItemPadding: 8
    property int listBottomPadding: 80

    Flickable {
        id: scrollView
        anchors.fill: parent
        contentHeight: contentColumn.implicitHeight + root.listBottomPadding
        clip: true

        Column {
            id: contentColumn
            width: parent.width
            spacing: root.todoListItemSpacing

            Repeater {
                model: ScriptModel {
                    values: root.taskList
                }
                delegate: Rectangle {
                    id: todoItemRectangle
                    required property var modelData
                    property bool pendingDoneToggle: false
                    property bool pendingDelete: false
                    property bool enableHeightAnimation: false

                    width: parent.width
                    height: todoContentRowLayout.implicitHeight
                    color: Appearance.colors.colLayer2
                    radius: Appearance.rounding.small
                    clip: true

                    scale: 0.0
                    opacity: 0.0

                    Component.onCompleted: {
                        appearAnimation.start();
                    }

                    SequentialAnimation {
                        id: appearAnimation
                        ParallelAnimation {
                            NumberAnimation { target: todoItemRectangle; property: "scale"; from: 0.6; to: 1.0; duration: 300; easing.type: Easing.OutBack }
                            NumberAnimation { target: todoItemRectangle; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
                        }
                    }

                    SequentialAnimation {
                        id: completeAnimation
                        ParallelAnimation {
                            NumberAnimation { target: todoItemRectangle; property: "scale"; to: 0.8; duration: 250; easing.type: Easing.InBack }
                            NumberAnimation { target: todoItemRectangle; property: "opacity"; to: 0.0; duration: 200 }
                            NumberAnimation { target: todoItemRectangle; property: "height"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                        }
                        ScriptAction {
                            script: {
                                if (!todoItemRectangle.modelData.done)
                                    Todo.markDone(todoItemRectangle.modelData.originalIndex);
                                else
                                    Todo.markUnfinished(todoItemRectangle.modelData.originalIndex);
                            }
                        }
                    }

                    SequentialAnimation {
                        id: deleteAnimation
                        ParallelAnimation {
                            NumberAnimation { target: todoItemRectangle; property: "scale"; to: 0.8; duration: 250; easing.type: Easing.InBack }
                            NumberAnimation { target: todoItemRectangle; property: "opacity"; to: 0.0; duration: 200 }
                            NumberAnimation { target: todoItemRectangle; property: "height"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                        }
                        ScriptAction {
                            script: {
                                Todo.deleteItem(todoItemRectangle.modelData.originalIndex);
                            }
                        }
                    }

                    RowLayout {
                        id: todoContentRowLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        TodoItemActionButton {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            onClicked: {
                                todoContentText.font.strikeout = !todoItemRectangle.modelData.done;
                                completeAnimation.start();
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: todoItemRectangle.modelData.done ? "radio_button_checked" : "radio_button_unchecked"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        StyledText {
                            id: todoContentText
                            Layout.fillWidth: true
                            Layout.topMargin: todoListItemPadding
                            Layout.bottomMargin: todoListItemPadding
                            text: todoItemRectangle.modelData.content
                            wrapMode: Text.Wrap
                            font.strikeout: todoItemRectangle.modelData.done
                            opacity: todoItemRectangle.modelData.done ? 0.5 : 1.0

                            Behavior on opacity {
                                NumberAnimation { duration: 250 }
                            }
                        }

                        TodoItemActionButton {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            onClicked: {
                                deleteAnimation.start();
                            }
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "delete_forever"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        // Placeholder when list is empty
        visible: opacity > 0
        opacity: taskList.length === 0 ? 1 : 0
        anchors.fill: parent

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                text: emptyPlaceholderIcon
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: emptyPlaceholderText
            }
        }
    }
}
