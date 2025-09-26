import QtQuick

RightTabBaseView {
    id: root

    signal sendToAddressRequested(string address)

    FollowingAddresses {
        objectName: "followingAddressesArea"
        width: root.width

        contactsStore: root.contactsStore
        networkConnectionStore: root.networkConnectionStore
        networksStore: root.networksStore

        onSendToAddressRequested: root.sendToAddressRequested(address)
    }
}
