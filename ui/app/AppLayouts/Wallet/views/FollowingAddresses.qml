import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import StatusQ.Components
import StatusQ.Core
import StatusQ.Core.Theme
import StatusQ.Controls.Validators

import SortFilterProxyModel

import utils
import shared.controls
import shared.stores as SharedStores
import AppLayouts.stores as AppLayoutStores

import AppLayouts.Wallet.stores
import AppLayouts.Wallet.controls

ColumnLayout {
    id: root

    property AppLayoutStores.ContactsStore contactsStore
    property SharedStores.NetworkConnectionStore networkConnectionStore
    property SharedStores.NetworksStore networksStore

    signal sendToAddressRequested(string address)

    QtObject {
        id: d

        function reset() {
            // Reset any state if needed
        }
    }

    SearchBox {
        id: searchBox
        Layout.fillWidth: true
        Layout.bottomMargin: Theme.padding
        visible: RootStore.followingAddresses.count > 0
        placeholderText: qsTr("Search for name, ENS or address")

        validators: [
            StatusValidator {
                property bool isEmoji: false

                name: "check-for-no-emojis"
                validate: (value) => {
                              if (!value) {
                                  return true
                              }

                              isEmoji = Constants.regularExpressions.emoji.test(value)
                              if (isEmoji){
                                  return false
                              }

                              return Constants.regularExpressions.alphanumericalExpanded1.test(value)
                          }
                errorMessage: isEmoji?
                                  qsTr("Your search is too cool (use A-Z and 0-9, single whitespace, hyphens and underscores only)")
                                : qsTr("Your search contains invalid characters (use A-Z and 0-9, single whitespace, hyphens and underscores only)")
            }
        ]
    }

    ShapeRectangle {
        id: noFollowingAddresses
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        visible: RootStore.followingAddresses.count === 0
        text: qsTr("Your EFP onchain friends will appear here")
    }

    ShapeRectangle {
        id: emptySearchResult
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        visible: RootStore.followingAddresses.count > 0 && listView.count === 0
        text: qsTr("No following addresses found. Check spelling or address is correct.")
    }

    StatusLoadingIndicator {
        id: loadingIndicator
        Layout.alignment: Qt.AlignHCenter
        visible: RootStore.loadingFollowingAddresses
        color: Theme.palette.directColor4
    }

    Item {
        visible: noFollowingAddresses.visible || emptySearchResult.visible
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    StatusListView {
        id: listView
        objectName: "FollowingAddressesView_followingAddresses"
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        spacing: 8

        model: SortFilterProxyModel {
            sourceModel: RootStore.followingAddresses
            delayed: true

            sorters: RoleSorter {
                roleName: "name"
                sortOrder: Qt.AscendingOrder
            }

            filters: ExpressionFilter {

                function spellingTolerantSearch(data, searchKeyword) {
                    const regex = new RegExp(searchKeyword.split('').join('.{0,1}'), 'i')
                    return regex.test(data)
                }

                enabled: !!searchBox.text && searchBox.valid

                expression: {
                    searchBox.text
                    let keyword = searchBox.text.trim().toUpperCase()
                    return spellingTolerantSearch(model.name, keyword) ||
                            model.address.toUpperCase().includes(keyword) ||
                            model.ensName.toUpperCase().includes(keyword)
                }
            }
        }

        section.property: "name"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: Item {
            height: 34
            width: children.width
            StatusBaseText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: section.toUpperCase()
                color: Theme.palette.baseColor1
                font.pixelSize: Theme.primaryTextFontSize
            }
        }

        delegate: FollowingAddressesDelegate {
            id: followingAddressDelegate
            objectName: "followingAddressView_Delegate_" + name
            name: model.name
            address: model.address
            ensName: model.ensName
            tags: model.tags
            networkConnectionStore: root.networkConnectionStore
            activeNetworks: root.networksStore.activeNetworks
            onOpenSendModal: root.sendToAddressRequested(recipient)
        }
    }
}
