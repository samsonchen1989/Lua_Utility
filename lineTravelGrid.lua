--[[
一种在TileMap实现Raycast的方法，可以用来检测视野是否阻挡等

Ref:
http://www.cse.yorku.ca/~amana/research/grid.pdf
http://www.flipcode.com/archives/Raytracing_Topics_Techniques-Part_4_Spatial_Subdivisions.shtml
https://gist.github.com/karussell/df699108fd8fbe0d44e1
]]--

local gridWidth = 10
local gridHeight = 10

local getTileByPos = function(x,y)
	local tileX = math.floor(x / gridWidth)
	local tileY = math.floor(y / gridHeight)

	return tileX + 1, tileY + 1
end

local lineTravelGrid =  function(x1,y1,x2,y2)
	local list = {}

	local startGridX, startGridY = getTileByPos(x1, y1)
	local endGridX, endGridY = getTileByPos(x2, y2)

	local deltaX = gridWidth / math.abs(x2 - x1)
	local stepX = (x2 - x1) > 0 and 1 or -1
	local tmp = x1 / gridWidth
	local maxX = deltaX * (1 - (tmp - math.floor(tmp)))

	local deltaY = gridHeight / math.abs(y2 - y1)
	local stepY = (y2 - y1) > 0 and 1 or -1
	tmp = y1 / gridHeight
	local maxY = deltaY * (1 - (tmp - math.floor(tmp)))

	local xEnd = false
	local yEnd = false

	while(not(xEnd and yEnd)) do
		if (maxX < maxY) then
			maxX = maxX + deltaX
			startGridX = startGridX + stepX
		else
			maxY = maxY + deltaY
			startGridY = startGridY + stepY
		end

		print("grid:{"..startGridX..","..startGridY.."}")
		table.insert(list, {startGridX, startGridY})

		-- check if travel to end point
        if stepX >= 0 then
            if startGridX >= endGridX then
                xEnd = true
            end
        else
            if startGridX <= endGridX then
                xEnd = true
            end
        end

        if stepY >= 0 then
            if startGridY >= endGridY then
                yEnd = true
            end
        else
            if startGridY <= endGridY then
                yEnd = true
            end
        end
	end
end

lineTravelGrid(5,4,25,24)
