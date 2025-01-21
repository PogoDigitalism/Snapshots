--!strict
local RunService = game:GetService("RunService")
local clock = os.clock

local Snapshot = {}
Snapshot.__index = Snapshot

type datetime = number
export type Snapshot = {
	-- fields
	_subject: Player?,
	_cache: {
		{
			o: T,
			d: datetime
		}
	},
	
	-- methods
	push: <T>(self: Snapshot, o: T) -> (),
	get: <T>(self: Snapshot, accuratePing: number) -> T,
	destroy: (self: Snapshot) -> (),
}

local lifetime = .15
local fps = 0
RunService.Heartbeat:Connect(function(dt)
	fps = 1/dt
end)

local snapshotInstances = {}
function Snapshot.getSnapshotInstance(player: Player): Snapshot
	return snapshotInstances[player] or Snapshot.registerPlayer(player)
end

function Snapshot.registerPlayer(player: Player)
	local snapshot = Snapshot.new(player)
	snapshotInstances[player] = snapshot
	
	return snapshot
end

function Snapshot.deregisterPlayer(player: Player)
	local snapshot = snapshotInstances[player]
	if snapshot then
		snapshotInstances[player] = nil
		snapshot:destroy()
	end
end

function Snapshot.new(subject: Player): Snapshot
	local self = setmetatable({}, Snapshot) :: Snapshot
	
	self._subject = subject
	self._cache = {}
	
	return self
end

function Snapshot.push<T>(self: Snapshot, o: T): ()
	local current = clock()
	
	local new = {}
	for _, v in self._cache do
		if current - v.d <= lifetime then
			table.insert(
				new,
				v
			)
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

function Snapshot.get<T>(self: Snapshot, accuratePing: number): T
	print(self._subject, accuratePing)
	local l = #self._cache
	if l == 0 then return nil
	elseif l == 1 or accuratePing > lifetime then return self._cache[1].o end
	
	local current = clock()
	
	for i = #self._cache - 1, 1, -1 do
		local latest = self._cache[i+1]
		local earliest = self._cache[i]
		
		local diff_l = current - latest.d
		local diff_e = current - earliest.d
		
		print(diff_l, diff_e)
		
		if accuratePing <= diff_l then return latest.o end -- is the ping lower than the latest entry
		
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

function Snapshot.destroy<T>(self: Snapshot): ()
	self._subject = nil
	table.clear(self._cache)
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self :: {})
end

return Snapshot
