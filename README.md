⚠️ unstable
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
  local ping = Snapshots.getAccuratePing(invoker)
  local playerSnapshot = Snapshots.getSnapshotInstance(target)

  return playerSnapshot:get(ping)
end

```
