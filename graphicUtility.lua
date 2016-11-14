-- Ref: http://www.phailed.me/2011/02/polygonal-collision-detection/
-- vectors are just lists
-- segments are tables: {start = vect, end = vect, dir = vect}
-- polygons includes {vertices = {vectors}, edge = {vectors}}

function vec(x, y)
	return {x, y}
end

v = vec -- shortcut

function dot(v1, v2)
	return v1[1]*v2[1] + v1[2]*v2[2]
end

function normalize(v)
	local mag = math.sqrt(v[1]^2 + v[2]^2)
	return vec(v[1]/mag, v[2]/mag)
end

function perp(v)
	return {v[2],-v[1]}
end

function segment(a, b)
	local obj = {a=a, b=b, dir={b[1] - a[1], b[2] - a[2]}}
	obj[1] = obj.dir[1]; obj[2] = obj.dir[2]
	return obj
end

function polygon(vertices)
	local obj = {}
	obj.vertices = vertices
	obj.edges = {}
	for i=1,#vertices do
		table.insert(obj.edges, segment(vertices[i], vertices[1+i%(#vertices)]))
	end
	return obj
end

function project(a, axis)
	axis = normalize(axis)
	local min = dot(a.vertices[1],axis)
	local max = min
	for i,v in ipairs(a.vertices) do
		local proj =  dot(v, axis) -- projection
		if proj < min then min = proj end
		if proj > max then max = proj end
	end

	return {min, max}
end

function contains(n, range)
	local a, b = range[1], range[2]
	if b < a then a = b; b = range[1] end
	return n >= a and n <= b
end

function overlap(a_, b_)
	if contains(a_[1], b_) then return true
	elseif contains(a_[2], b_) then return true
	elseif contains(b_[1], a_) then return true
	elseif contains(b_[2], a_) then return true
	end
	return false
end


function sat(a, b)
	for i,v in ipairs(a.edges) do
		local axis = perp(v)
		local a_, b_ = project(a, axis), project(b, axis)
		if not overlap(a_, b_) then return false end
	end
	for i,v in ipairs(b.edges) do
		local axis = perp(v)
		local a_, b_ = project(a, axis), project(b, axis)
		if not overlap(a_, b_) then return false end
	end

	return true
end

-- Check whether a point inside a polygon, lua version
-- Ref: https://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
local isPointInPolygon = function(p, polygon)
	local inside = false

	local i = 1
	local j = #(polygon.vertices)

	while (i <= #(polygon.vertices)) do
		if ( ((polygon.vertices[i][2] > p[2]) ~= (polygon.vertices[j][2] > p[2])) and
		     (p[1] < (polygon.vertices[j][1] - polygon.vertices[i][1]) * (p[2] - polygon.vertices[i][2]) / (polygon.vertices[j][2] - polygon.vertices[i][2]) + polygon.vertices[i][1])) then
			inside = not inside
		end

		j = i
		i = i + 1
	end

	return inside
end

local a = polygon{v(5, 3), v(-3, 6), v(-1, 3), v(-3, 1)}
local b = polygon{v(3, 1), v(1, 5), v(7,5), v(5, 2)}
local p = v(6, 4)

local main = function()
	local time = os.clock()

	print("check poly joint result:", sat(a, b))
	print("check point result:", isPointInPolygon(p, b))
end


main()
