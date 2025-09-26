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
  
  # Handle tags array manually since getProp doesn't support seq[string]
  if jsonObj.hasKey("tags") and jsonObj["tags"].kind == JArray:
    result.tags = @[]
    for tag in jsonObj["tags"]:
      if tag.kind == JString:
        result.tags.add(tag.getStr())
  else:
    result.tags = @[]
    
  # ensName will be set separately via ENS resolution
  result.ensName = ""

proc toJsonNode*(self: FollowingAddressDto): JsonNode =
  result = %* {
    "address": self.address,
    "tags": self.tags,
    "ensName": self.ensName
  }
