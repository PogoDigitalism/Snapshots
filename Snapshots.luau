--!strict
local RunService = game:GetService("RunService")
local clock = os.clock

local Snapshot = {}
Snapshot.__index = Snapshot

type datetime = number
export type Snapshot<T> = {
	-- fields
	_subject: Player,
	_cache: {
		{
			o: T,
			d: datetime
		}
	},
	
	-- methods
	push: <T>(self: Snapshot<T>, o: T) -> ()
}
local lifetime = 150
local fps = 0
RunService.Heartbeat:Connect(function(dt)
	fps = 1/dt
end)

local snapshotInstances = {}
function Snapshot.getSnapshotInstance<T>(player: Player): Snapshot<T>
	return snapshotInstances[player] or Snapshot.registerPlayer(player)
end

function Snapshot.registerPlayer<T>(player: Player)
	local snapshot = Snapshot.new(player)
	snapshotInstances[player] = snapshot
	
	return snapshot
end

function Snapshot.getAccuratePing(player: Player): number
	return player:GetNetworkPing() + (1 / fps) + (1 / 60)
end

function Snapshot.new<T>(subject: Player): Snapshot<T>
	local self = setmetatable({}, Snapshot) :: Snapshot<T>
	
	self._subject = subject
	self._cache = {}
	
	return self
end

function Snapshot.push<T>(self: Snapshot<T>, o: T): ()
	local current = clock()
	
	local new = {}
	for i = #self._cache, 1, -1 do
		local v = self._cache[i]
		if current - v.d <= lifetime then
			table.insert(
				new,
				v
			)
		else
			break -- we can stop iterating because every entry after will be too old
		end
	end
	self._cache = new
	
	table.insert(
		self._cache,
		{
			["o"] = o,
			["d"] = clock()
		}
	)
end

function Snapshot.get<T>(self: Snapshot<T>, accuratePing: number): T
	local l = #self._cache
	if l == 0 then return nil
	elseif l == 1 or accuratePing > lifetime then return self._cache[l].o end
	
	local current = clock()
	
	for i = #self._cache - 1, 1, -1 do
		local latest = self._cache[i+1]
		local earliest = self._cache[i]
		
		local diff_l = current - latest.d
		local diff_e = current - earliest.d
		
		if accuratePing <= diff_l then return latest.o end -- is the ping lower than the latest entry
		if i == 1 and accuratePing > diff_e then return self._cache[i].o end -- is the player's ping higher than the lifetime 
		
		if accuratePing <= diff_e then -- is the ping lower than the earliest entry, then its between latest and earlier, so lerp
			if typeof(latest.o) == "CFrame" then
				local cframe_l: CFrame = latest.o
				local cframe_e: CFrame = earliest.o
				
				local a = (accuratePing - diff_l) / (diff_e - diff_l)
				return cframe_e:Lerp(cframe_l, a)
			else
				return nil
				-- TODO
			end
		end
	end
	return nil
end

return Snapshot
