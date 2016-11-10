-- Check whether a point inside a polygon, lua version
-- Ref: https://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
local IsPointInPolygon = function(p, polygon)
	local inside = false

	local i = 1
	local j = #polygon

	while (i <= #polygon) do
		if ( ((polygon[i].y > p.y) ~= (polygon[j].y > p.y)) and
		     (p.x < (polygon[j].x - polygon[i].x) * (p.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x)) then
			inside = not inside
		end

		j = i
		i = i + 1
	end

	return inside
end

local test = {
	{x = 3, y = 5},
	{x = 3, y = 6},
	{x = 2, y = 2},
	{x = 4, y = 3},
	{x = 6, y = 3},
	{x = 5, y = 3},
}

-- Clock-wise point list, otherwise may get opposite result
local polygon = {
	{x = 2, y = 2},
	{x = 2, y = 5},
	{x = 4, y = 6},
	{x = 6, y = 2},
}

for k,v in pairs(test) do
	print("x:"..v.x..", y:"..v.y)
	print("Is in polygon:", IsPointInPolygon(v, polygon))
end

-- Ref: http://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon
