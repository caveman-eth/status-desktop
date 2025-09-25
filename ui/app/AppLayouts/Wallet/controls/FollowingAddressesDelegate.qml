import QtQuick
import QtQuick.Controls

import utils

import StatusQ
import StatusQ.Controls
import StatusQ.Components
import StatusQ.Core
import StatusQ.Core.Theme
import StatusQ.Core.Utils as StatusQUtils
import StatusQ.Popups

import shared.controls
import shared.popups
import shared.stores as SharedStores

import "../popups"
import "../controls"
import "../stores"
import ".."

StatusListItem {
    id: root

    property SharedStores.NetworkConnectionStore networkConnectionStore
    property var activeNetworks
    property string name
    property string address
    property string ensName
    property var tags

    property int usage: FollowingAddressesDelegate.Usage.Delegate
    property bool showButtons: sensor.containsMouse

    property alias sendButton: sendButton
    property alias starButton: starButton

    signal aboutToOpenPopup()
    signal openSendModal(string recipient)
    signal addToSavedAddresses(string address, string name, string ensName)

    enum Usage {
        Delegate,
        Item
    }

    implicitWidth: ListView.view ? ListView.view.width : 0

    title: name
    objectName: name
    subTitle: {
        if (ensName.length > 0)
            return ensName
        else {
            return WalletUtils.addressToDisplay(root.address, false, sensor.containsMouse)
        }
    }

    border.color: Theme.palette.baseColor5

    asset {
        width: 40
        height: 40
        color: Theme.palette.primaryColor1
        isLetterIdenticon: true
        letterIdenticonBgWithAlpha: true
    }

    statusListItemIcon.hoverEnabled: true

    statusListItemComponentsSlot.spacing: 0

    QtObject {
        id: d

        readonly property string visibleAddress: !!root.ensName ? root.ensName : root.address
    }

    onClicked: {
        if (root.usage === FollowingAddressesDelegate.Usage.Item) {
            return
        }
        // Could open following address details popup in the future
    }

    components: [
        StatusRoundButton {
            id: starButton
            visible: !!root.name && root.showButtons
            type: StatusRoundButton.Type.Quinary
            radius: 8
            icon.name: "star"
            tooltip.text: qsTr("Add to saved addresses")
            onClicked: root.addToSavedAddresses(root.address, root.name, root.ensName)
        },
        StatusRoundButton {
            id: sendButton
            visible: !!root.name && root.showButtons
            type: StatusRoundButton.Type.Quinary
            radius: 8
            icon.name: "send"
            enabled: root.networkConnectionStore.sendBuyBridgeEnabled
            onClicked: root.openSendModal(d.visibleAddress)
        },
        StatusRoundButton {
            objectName: "followingAddressView_Delegate_menuButton_" + root.name
            visible: !!root.name
            enabled: root.showButtons
            type: StatusRoundButton.Type.Quinary
            radius: 8
            icon.name: "more"
            onClicked: {
                menu.openMenu(this, x + width - menu.width - statusListItemComponentsSlot.spacing, y + height + Theme.halfPadding,
                    {
                        name: root.name,
                        address: root.address,
                        ensName: root.ensName,
                        tags: root.tags,
                    }
                );
            }

        }
    ]

    StatusMenu {
        id: menu
        property string name
        property string address
        property string ensName
        property var tags

        readonly property int maxHeight: 341
        height: implicitHeight > maxHeight ? maxHeight : implicitHeight

        function openMenu(parent, x, y, model) {
            menu.name = model.name;
            menu.address = model.address;
            menu.ensName = model.ensName;
            menu.tags = model.tags;
            popup(parent, x, y);
        }
        onClosed: {
            menu.name = "";
            menu.address = "";
            menu.ensName = ""
            menu.tags = []
        }

        StatusSuccessAction {
            id: copyAddressAction
            objectName: "copyFollowingAddressAction"
            successText: qsTr("Address copied")
            text: qsTr("Copy address")
            icon.name: "copy"
            timeout: 1500
            autoDismissMenu: true
            onTriggered: ClipboardUtils.setText(d.visibleAddress)
        }

        StatusAction {
            text: qsTr("Show address QR")
            objectName: "showQrFollowingAddressAction"
            assetSettings.name: "qr"
            onTriggered: {
                if (root.usage === FollowingAddressesDelegate.Usage.Item) {
                    root.aboutToOpenPopup()
                }
                Global.openShowQRPopup({
                                           showSingleAccount: true,
                                           showForSavedAddress: false,
                                           switchingAccounsEnabled: false,
                                           hasFloatingButtons: false,
                                           name: menu.name,
                                           address: menu.address
                                       })
            }
        }

        StatusAction {
            text: qsTr("View activity")
            objectName: "viewActivityFollowingAddressAction"
            assetSettings.name: "wallet"
            onTriggered: {
                if (root.usage === FollowingAddressesDelegate.Usage.Item) {
                    root.aboutToOpenPopup()
                }
                Global.changeAppSectionBySectionType(Constants.appSection.wallet,
                                                     WalletLayout.LeftPanelSelection.AllAddresses,
                                                     WalletLayout.RightPanelSelection.Activity,
                                                     {savedAddress: menu.address})
            }
        }

        StatusMenuSeparator {}

        BlockchainExplorersMenu {
            id: blockchainExplorersMenu
            flatNetworks: root.activeNetworks
            onNetworkClicked: {
                let link = Utils.getUrlForAddressOnNetwork(shortname, isTestnet, d.visibleAddress ? d.visibleAddress : root.ensName);
                Global.openLinkWithConfirmation(link, StatusQUtils.StringUtils.extractDomainFromLink(link));
            }
        }

        StatusMenuSeparator { }

        StatusAction {
            text: qsTr("Add to saved addresses")
            assetSettings.name: "star"
            objectName: "addToSavedAddressesAction"
            onTriggered: {
                if (root.usage === FollowingAddressesDelegate.Usage.Item) {
                    root.aboutToOpenPopup()
                }
                root.addToSavedAddresses(menu.address, menu.name, menu.ensName)
            }
        }
    }
}
