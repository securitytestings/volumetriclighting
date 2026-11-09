local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local BatchLoadingManager = {}

----------------------------------
-- config

BatchLoadingManager.MaximumDistance = 60

local BATCH_INTERVAL = 0.05 -- min seconds between batches
local MAX_BATCH = 300       -- max checks per batch; the rest roll into the next one
local NO_PLAYER_RETRY = 0.5 -- seconds to wait when the character isn't ready

----------------------------------
-- state

BatchLoadingManager._queue = {}
BatchLoadingManager._queued = {}
BatchLoadingManager._results = {}

local listeners = {}
local lastBatchTime = 0
local retryScheduled = false

----------------------------------
-- queue

function BatchLoadingManager.QueueCheck(position: Vector3, identifier: string)
	if typeof(position) ~= "Vector3" then
		warn("QueueCheck: Invalid position provided")
		return nil
	end

	local existing = BatchLoadingManager._queued[identifier]
	if existing then
		existing.position = position
	else
		local entry = {position = position, id = identifier, cancelled = false}
		BatchLoadingManager._queued[identifier] = entry
		table.insert(BatchLoadingManager._queue, entry)
	end

	return BatchLoadingManager._results[identifier]
end

function BatchLoadingManager.Forget(identifier: string)
	local entry = BatchLoadingManager._queued[identifier]
	if entry then
		entry.cancelled = true
		BatchLoadingManager._queued[identifier] = nil
	end
	BatchLoadingManager._results[identifier] = nil
end

----------------------------------
-- listeners

function BatchLoadingManager.OnBatchCompleted(callback)
	listeners[callback] = true
	return function()
		listeners[callback] = nil
	end
end

----------------------------------
-- processing

local function scheduleProcess(delay: number)
	if retryScheduled then return end
	retryScheduled = true

	task.delay(delay, function()
		retryScheduled = false
		BatchLoadingManager.ProcessBatch()
	end)
end

function BatchLoadingManager.ProcessBatch()
	local queue = BatchLoadingManager._queue
	local total = #queue
	if total == 0 then return end

	local sinceLast = os.clock() - lastBatchTime
	if sinceLast < BATCH_INTERVAL then
		scheduleProcess(BATCH_INTERVAL - sinceLast)
		return
	end

	local character = Player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		scheduleProcess(NO_PLAYER_RETRY)
		return
	end
	local playerPos = rootPart.Position

	local maxDistance = BatchLoadingManager.MaximumDistance
	local maxSq = maxDistance * maxDistance
	local results = BatchLoadingManager._results
	local queued = BatchLoadingManager._queued

	local count = math.min(total, MAX_BATCH)
	for i = 1, count do
		local entry = queue[i]
		if queued[entry.id] == entry then
			queued[entry.id] = nil
		end
		if not entry.cancelled then
			local d = entry.position - playerPos
			results[entry.id] = d:Dot(d) <= maxSq
		end
	end

	table.move(queue, count + 1, total, 1)
	for i = total - count + 1, total do
		queue[i] = nil
	end

	lastBatchTime = os.clock()

	for callback in listeners do
		task.spawn(callback, results)
	end

	if #queue > 0 then
		scheduleProcess(BATCH_INTERVAL)
	end
end

function BatchLoadingManager.ClearResults()
	table.clear(BatchLoadingManager._results)
end

function BatchLoadingManager.ResetQueue()
	for _, entry in BatchLoadingManager._queue do
		entry.cancelled = true
	end
	table.clear(BatchLoadingManager._queue)
	table.clear(BatchLoadingManager._queued)
end

return BatchLoadingManager
