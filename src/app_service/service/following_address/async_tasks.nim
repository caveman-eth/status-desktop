include app_service/common/json_utils
include app/core/tasks/common

import backend/following_addresses as backend

type
  FetchFollowingAddressesTaskArg = ref object of QObjectTaskArg
    userAddress: string

proc fetchFollowingAddressesTask*(argEncoded: string) {.gcsafe, nimcall.} =
  let arg = decode[FetchFollowingAddressesTaskArg](argEncoded)
  var output = %*{
    "followingAddresses": "",
    "userAddress": arg.userAddress,
    "error": ""
  }
  try:
    let response = backend.getFollowingAddresses(arg.userAddress)
    output["followingAddresses"] = %*response
  except Exception as e:
    output["error"] = %* fmt"Error fetching following addresses: {e.msg}"
  arg.finish(output)
