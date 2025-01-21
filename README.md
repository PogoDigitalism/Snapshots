⚠️ not rigorously tested, but studio-based tests have passed
# Snapshots
My implementation of a snapshot system in Luau (primarily for lag compensation)

Source:
https://developer.valvesoftware.com/wiki/Lag_Compensation

# Example
```luau
ReplicationPackets.ReplicatePosition.listen(function(data: CFrame, player: Player)
  ...
  local playerSnapshot = Snapshots.getSnapshotInstance(player)
  playerSnapshot:push(data)
  ...
end)

function UptodatePositions.getCFrame(invoker: Player, target: Player): CFrame
  local ping = ... -- get ping from your accurate latency module (so NOT :GetNetworkPing())
  local playerSnapshot = Snapshots.getSnapshotInstance(target)

  return playerSnapshot:get(ping)
end

```
