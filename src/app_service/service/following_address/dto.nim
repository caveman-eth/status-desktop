import json, strutils

include ../../common/json_utils

type
  FollowingAddressDto* = ref object of RootObj
    address*: string
    tags*: seq[string]
    ensName*: string  # Will be resolved separately

proc toFollowingAddressDto*(jsonObj: JsonNode): FollowingAddressDto =
  result = FollowingAddressDto()
  discard jsonObj.getProp("address", result.address)
  discard jsonObj.getProp("tags", result.tags)
  # ensName will be set separately via ENS resolution
  result.ensName = ""

proc toJsonNode*(self: FollowingAddressDto): JsonNode =
  result = %* {
    "address": self.address,
    "tags": self.tags,
    "ensName": self.ensName
  }
