import nimqml, chronicles, strutils, sequtils, json, tables

import dto

import backend/following_addresses as backend
import app/core/eventemitter
import app/core/signals/types
import app/core/[main]
import app/core/tasks/[qt, threadpool]
import app_service/service/network/service as network_service

export dto

include async_tasks

logScope:
  topics = "following-address-service"

# Signals which may be emitted by this service:
const SIGNAL_FOLLOWING_ADDRESSES_UPDATED* = "followingAddressesUpdated"
const SIGNAL_FOLLOWING_ADDRESSES_ABOUT_TO_BE_UPDATED* = "followingAddressesAboutToBeUpdated"

type
  FollowingAddressesArgs* = ref object of Args
    userAddress*: string
    addresses*: seq[FollowingAddressDto]

QtObject:
  type Service* = ref object of QObject
    threadpool: ThreadPool
    events: EventEmitter
    followingAddressesTable: Table[string, seq[FollowingAddressDto]]
    followingAddressesLoading: bool
    hasCacheData: bool
    networkService: network_service.Service

  proc delete*(self: Service) =
    self.QObject.delete

  proc newService*(threadpool: ThreadPool, events: EventEmitter, networkService: network_service.Service): Service =
    new(result, delete)
    result.QObject.setup
    result.threadpool = threadpool
    result.events = events
    result.networkService = networkService
    result.followingAddressesTable = initTable[string, seq[FollowingAddressDto]]()
    result.followingAddressesLoading = false
    result.hasCacheData = false

  proc init*(self: Service) =
    discard

  proc getFollowingAddresses*(self: Service, userAddress: string): seq[FollowingAddressDto] =
    if self.followingAddressesTable.hasKey(userAddress):
      return self.followingAddressesTable[userAddress]
    return @[]

  proc fetchFollowingAddresses*(self: Service, userAddress: string) =
    self.followingAddressesLoading = true
    defer: self.events.emit(SIGNAL_FOLLOWING_ADDRESSES_ABOUT_TO_BE_UPDATED, Args())
    
    let arg = FetchFollowingAddressesTaskArg(
      tptr: fetchFollowingAddressesTask,
      vptr: cast[uint](self.vptr),
      slot: "onFollowingAddressesFetched",
      userAddress: userAddress
    )
    self.threadpool.start(arg)

  proc onFollowingAddressesFetched(self: Service, response: string) {.slot.} =
    self.followingAddressesLoading = false
    defer: self.events.emit(SIGNAL_FOLLOWING_ADDRESSES_UPDATED, Args())
    try:
      let parsedJson = response.parseJson
      var errorString: string
      var userAddress: string
      var followingAddressesJson: JsonNode
      discard parsedJson.getProp("followingAddresses", followingAddressesJson)
      discard parsedJson.getProp("userAddress", userAddress)
      discard parsedJson.getProp("error", errorString)

      if not errorString.isEmptyOrWhitespace:
        raise newException(Exception, "Error fetching following addresses: " & errorString)
      if followingAddressesJson.isNil or followingAddressesJson.kind == JNull:
        return

      let addresses = followingAddressesJson.result.getElems().map(x => x.toFollowingAddressDto())
      
      # Update cache
      self.followingAddressesTable[userAddress] = addresses
      self.hasCacheData = true
      
    except Exception as e:
      error "onFollowingAddressesFetched", msg = e.msg

  proc isFollowingAddressesLoading*(self: Service): bool =
    return self.followingAddressesLoading

  proc hasFollowingAddressesCache*(self: Service): bool =
    return self.hasCacheData
