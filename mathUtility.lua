local lerp = function(start, target, by)
    by = math.min(1, by)
    return start + (target - start) * by
end

--角度间的线性差值，会检测两个角度差判断是顺时针变换还是逆时针变换
local radianLerp = function(start, target, by)
    by = math.min(1, by)
    if math.abs(target - start) > math.pi then
        if (target > start) then
            start = start + 2 * math.pi
        else
            target = target + 2 * math.pi
        end
    end

    local result = lerp(start, target, by)
    if not (result >= 0 and result <= 2 * math.pi) then
        result = result % (2 * math.pi)
    end

    return result
end

print("radianLerp test1:", radianLerp(0.1 * math.pi, 1.8 * math.pi, 0.8) * 180 / 3.1415)
print("radianLerp test2:", radianLerp(1.8 * math.pi, 0.1 * math.pi, 0.8) * 180 / 3.1415)


local vector2Lerp = function(startVector, targetVector, by)
    local x = lerp(startVector.x, targetVector.x, by)
    local y = lerp(startVector.y, targetVector.y, by)

    return {x = x, y = y}
end

local result = vector2Lerp({x = 0, y = 1}, {x = 1, y = 0}, 0.5)
print("vector2Lerp test, x:"..result.x..", y:"..result.y)
