import nimqml, sugar, sequtils
import ../io_interface as delegate_interface

import app/global/global_singleton
import app/core/eventemitter
import app_service/service/following_address/service as following_address_service

import io_interface, view, controller, model

export io_interface

type
  Module* = ref object of io_interface.AccessInterface
    delegate: delegate_interface.AccessInterface
    view: View
    viewVariant: QVariant
    moduleLoaded: bool
    controller: Controller

proc newModule*(
  delegate: delegate_interface.AccessInterface,
  events: EventEmitter,
  followingAddressService: following_address_service.Service,
): Module =
  result = Module()
  result.delegate = delegate
  result.view = newView(result)
  result.viewVariant = newQVariant(result.view)
  result.controller = newController(result, events, followingAddressService)
  result.moduleLoaded = false

method delete*(self: Module) =
  self.viewVariant.delete
  self.view.delete

method loadFollowingAddresses*(self: Module, userAddress: string) =
  let followingAddresses = self.controller.getFollowingAddresses(userAddress)
  self.view.setItems(
    followingAddresses.map(f => initItem(
      f.address,
      f.ensName,
      f.tags,
    ))
  )

method load*(self: Module) =
  singletonInstance.engine.setRootContextProperty("walletSectionFollowingAddresses", self.viewVariant)

  # We'll load following addresses when user navigates to the section
  self.controller.init()
  self.view.load()

method isLoaded*(self: Module): bool =
  return self.moduleLoaded

method viewDidLoad*(self: Module) =
  self.moduleLoaded = true
  self.delegate.followingAddressesModuleDidLoad()

method fetchFollowingAddresses*(self: Module, userAddress: string) =
  self.controller.fetchFollowingAddresses(userAddress)
