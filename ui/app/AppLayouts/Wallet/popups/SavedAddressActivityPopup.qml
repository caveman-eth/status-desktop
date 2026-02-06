import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import StatusQ
import StatusQ.Core
import StatusQ.Core.Theme
import StatusQ.Controls
import StatusQ.Popups.Dialog
import StatusQ.Core.Utils as StatusQUtils

import AppLayouts.stores
import AppLayouts.Wallet.stores as WalletStore
import AppLayouts.Wallet.controls

import shared.controls
import shared.views
import shared.stores as SharedStores

import utils

StatusDialog {
    id: root

    property SharedStores.NetworkConnectionStore networkConnectionStore
    property ContactsStore contactsStore
    required property SharedStores.NetworksStore networksStore

    signal sendToAddressRequested(string address)

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    implicitWidth: d.popupWidth
    implicitHeight: d.popupHeight

    onClosed: {
        root.close()
        if (!d.isFollowingAddress) {
            walletSection.activityController.setFilterToAddresses(JSON.stringify([]))
            walletSection.activityController.updateFilter()
        }
    }

    function initWithParams(params = {}) {
        d.name = params.name?? ""
        d.address = params.address?? Constants.zeroAddress
        d.mixedcaseAddress = params.mixedcaseAddress?? Constants.zeroAddress
        d.ens = params.ens?? ""
        d.colorId = params.colorId?? ""
        d.avatar = params.avatar?? ""
        d.isFollowingAddress = params.isFollowingAddress?? false

        if (d.isFollowingAddress)
            root.implicitHeight = d.followingPopupHeight

        if (!d.isFollowingAddress) {
            walletSection.activityController.setFilterToAddresses(JSON.stringify([d.address]))
            walletSection.activityController.updateFilter()
        }
    }

    QtObject {
        id: d

        readonly property int popupWidth: 477
        readonly property int popupHeight: 672
        readonly property int followingPopupHeight: 250

        property string name: ""
        property string address: Constants.zeroAddress
        property string mixedcaseAddress: Constants.zeroAddress
        property string ens: ""
        property string colorId: ""
        property string avatar: ""
        property bool isFollowingAddress: false

        readonly property string visibleAddress: !!d.ens? d.ens : d.address

        readonly property int yRange: historyView.firstItemOffset
        readonly property real extendedViewOpacity: {
            if (historyView.yPosition <= 0) {
                return 1
            }

            let op = 1 - historyView.yPosition / d.yRange
            if (op > 0) {
                return op
            }

            return 0
        }
        readonly property bool showSplitLine: d.extendedViewOpacity === 0
    }

    component Spacer: Item {
        width: 1
    }

    padding: Theme.bigPadding
    footer: null

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.padding

        SavedAddressesDelegate {
            id: savedAddress

            Layout.preferredHeight: 72
            Layout.fillWidth: true

            leftPadding: 0
            rightPadding: 0
            border.color: StatusColors.transparent

            usage: SavedAddressesDelegate.Usage.Item
            showButtons: true
            statusListItemComponentsSlot.spacing: 4

            statusListItemSubTitle.visible: d.extendedViewOpacity !== 1
            statusListItemSubTitle.opacity: 1 - d.extendedViewOpacity
            statusListItemSubTitle.customColor: Theme.palette.directColor1
            statusListItemSubTitle.text: {
                if (statusListItemSubTitle.visible) {
                    if (!!d.ens) {
                        return d.ens
                    }
                    else {
                        return Utils.richColorText(StatusQUtils.Utils.elideText(d.address,6,4), Theme.palette.directColor1)
                    }
                }
                return ""
            }

            sendButton.visible: d.extendedViewOpacity !== 1
            sendButton.opacity: 1 - d.extendedViewOpacity
            sendButton.type: StatusRoundButton.Type.Primary

            asset.width: 72
            asset.height: 72
            asset.letterSize: 32
            bgColor: Theme.palette.statusListItem.backgroundColor

            networkConnectionStore: root.networkConnectionStore
            activeNetworks: root.networksStore.activeNetworks

            name: d.name
            address: d.address
            ens: d.ens
            colorId: d.colorId
            mixedcaseAddress: d.mixedcaseAddress
            avatar: d.avatar
            isFollowingAddress: d.isFollowingAddress

            statusListItemTitle.font.pixelSize: Theme.fontSize(22)
            statusListItemTitle.font.bold: Font.Bold

            onAboutToOpenPopup: {
                root.close()
            }
            onOpenSendModal: {
                root.sendToAddressRequested(recipient)
                root.close()
            }
        }

        StatusDialogDivider {
            Layout.topMargin: -Theme.padding
            Layout.fillWidth: true
            visible: d.showSplitLine
        }

        ColumnLayout {
            Layout.fillWidth: true

            spacing: Theme.padding
            opacity: d.extendedViewOpacity
            visible: opacity > 0.01

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addressColumn.height + Theme.bigPadding

                color: StatusColors.transparent
                radius: Theme.radius
                border.color: Theme.palette.baseColor2
                border.width: 1

                Column {
                    id: addressColumn
                    anchors.left: parent.left
                    anchors.right: copyButton.left
                    anchors.rightMargin: Theme.padding
                    anchors.leftMargin: Theme.padding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StatusBaseText {
                        id: ensText
                        width: parent.width
                        visible: !!d.ens
                        text: d.ens
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: Theme.primaryTextFontSize
                        color: Theme.palette.directColor1
                    }

                    StatusBaseText {
                        id: addressText
                        width: parent.width
                        text: d.address
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: !!d.ens ? Theme.additionalTextSize : Theme.primaryTextFontSize
                        color: !!d.ens ? Theme.palette.baseColor1 : Theme.palette.directColor1
                    }
                }

                CopyButtonWithCircle {
                    id: copyButton
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.padding
                    anchors.verticalCenter: addressColumn.verticalCenter
                    textToCopy: d.address
                }
            }

            StatusButton {
                Layout.fillWidth: true

                radius: Theme.radius
                text: qsTr("Send")
                icon.name: "send"
                enabled: root.networkConnectionStore.sendBuyBridgeEnabled
                onClicked: {
                    root.sendToAddressRequested(d.visibleAddress)
                    root.close()
                }
            }
        }

        HistoryView {
            id: historyView

            Layout.fillWidth: true

            visible: !d.isFollowingAddress

            disableShadowOnScroll: true
            hideVerticalScrollbar: true
            displayValues: false
            firstItemOffset: 1
            overview: ({
                           isWatchOnlyAccount: false,
                           mixedcaseAddress: d.address
                       })
            activityStore: WalletStore.RootStore
            networksStore: root.networksStore
        }

        Item {
            Layout.fillHeight: true
            visible: d.isFollowingAddress
        }
    }
}
