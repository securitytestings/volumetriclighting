return function(playerPos, MaximumDistance, positions, PositionCount, identifiers)
	if type(positions[1]) == "number" then
		local targetPos = Vector3.new(positions[1], positions[2], positions[3])
		return (playerPos - targetPos).Magnitude <= MaximumDistance
	end

	local results = {}

	for i = 1, PositionCount do
		local position = positions[i]
		local key = identifiers and identifiers[i] or i

		if position and position[1] and position[2] and position[3] then
			local targetPos = Vector3.new(position[1], position[2], position[3])
			results[key] = (playerPos - targetPos).Magnitude <= MaximumDistance
		else
			results[key] = false
		end
	end

	return results
end
