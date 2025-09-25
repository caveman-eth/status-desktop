import io_interface
import app/core/eventemitter
import app_service/service/following_address/service as following_address_service

type
  Controller* = ref object of RootObj
    delegate: io_interface.AccessInterface
    events: EventEmitter
    followingAddressService: following_address_service.Service

proc newController*(
  delegate: io_interface.AccessInterface,
  events: EventEmitter,
  followingAddressService: following_address_service.Service
): Controller =
  result = Controller()
  result.delegate = delegate
  result.events = events
  result.followingAddressService = followingAddressService

proc delete*(self: Controller) =
  discard

proc init*(self: Controller) =
  self.events.on(SIGNAL_FOLLOWING_ADDRESSES_UPDATED) do(e:Args):
    # For now, we'll need to track which user address was fetched
    # This can be enhanced later with proper user address tracking
    self.delegate.loadFollowingAddresses("")

proc getFollowingAddresses*(self: Controller, userAddress: string): seq[following_address_service.FollowingAddressDto] =
  return self.followingAddressService.getFollowingAddresses(userAddress)

proc fetchFollowingAddresses*(self: Controller, userAddress: string) =
  self.followingAddressService.fetchFollowingAddresses(userAddress)

proc isFollowingAddressesLoading*(self: Controller): bool =
  return self.followingAddressService.isFollowingAddressesLoading()

proc hasFollowingAddressesCache*(self: Controller): bool =
  return self.followingAddressService.hasFollowingAddressesCache()
