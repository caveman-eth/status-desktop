import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import StatusQ.Components
import StatusQ.Core
import StatusQ.Core.Theme
import StatusQ.Controls

import utils
import shared.controls
import shared.stores as SharedStores
import AppLayouts.stores as AppLayoutStores

import AppLayouts.Wallet.stores

WalletBaseView {
    id: root

    property alias headerButton: headerButton
    property alias networkFilter: networkFilter

    property AppLayoutStores.ContactsStore contactsStore
    property SharedStores.NetworkConnectionStore networkConnectionStore
    property SharedStores.NetworksStore networksStore

    signal sendToAddressRequested(string address)

    headerButton: StatusButton {
        id: headerButton
        objectName: "walletHeaderButton"
        size: StatusBaseButton.Size.Small
        normalColor: "transparent"
        hoverColor: Theme.palette.primaryColor3
        textColor: Theme.palette.primaryColor1
        borderColor: Theme.palette.primaryColor1
        text: qsTr("Refresh following")
        onClicked: {
            // Get user's primary wallet address and fetch following addresses
            let userAddress = RootStore.overview.mixedcaseAddress
            if (userAddress) {
                RootStore.fetchFollowingAddresses(userAddress)
            }
        }
    }

    networkFilter: NetworkFilter {
        id: networkFilter
        objectName: "followingAddressesNetworkFilter"
        flatNetworks: root.networksStore.flatNetworks
        // Following addresses don't need network filtering like saved addresses
        visible: false
    }

    FollowingAddresses {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contactsStore: root.contactsStore
        networkConnectionStore: root.networkConnectionStore
        networksStore: root.networksStore
        onSendToAddressRequested: root.sendToAddressRequested(address)
    }
}
