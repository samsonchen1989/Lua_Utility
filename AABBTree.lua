local fatMargin = 100

-- Point = {x, y}
-- Polygon = { {x1,y1}, {x2,y2}, {x3,y3}, {x4,y4} }
-- AABB = {minX, maxX, minY, maxY}
-- AABB树，比较适合做简单场景（少量动态，多数静态）的AABB框碰撞检测

local fastMin = math.min
local fastMax = math.max
local fastSqrt = math.sqrt

local function union(aabb1, aabb2)
    if aabb1 and aabb2 then
        return {fastMin(aabb1[1], aabb2[1]), fastMax(aabb1[2], aabb2[2]), fastMin(aabb1[3], aabb2[3]), fastMax(aabb1[4], aabb2[4])}
    end

    return aabb1 or aabb2
end

local function volume(aabb)
    return (aabb[2] - aabb[1]) * (aabb[4] - aabb[3])
end

local function isOut(aabb1, aabb2)
    if not (aabb1 and aabb2) then
        return false
    end

    return (aabb1[1] < aabb2[1] or aabb1[2] > aabb2[2] or aabb1[3] < aabb2[3] or aabb1[4] > aabb2[4])
end

local AABBTree = {}
AABBTree.__index = AABBTree

function AABBTree.new(t)
    t = t or {}
    setmetatable(t, AABBTree)

    return t
end

setmetatable(AABBTree, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function AABBTree:insert(data)
    if not self.aabb then
        -- first node
        self:setLeaf(data)
        self:updateAABB()
        return
    else
        local node = AABBTree()
        node:setLeaf(data)
        node:updateAABB()
        -- Insert node
        AABBTree.insertNode(node, self)
    end
end

function AABBTree.insertNode(node, parentNode)
    if parentNode.isLeaf == true then
        -- set parentNode to leaf node and add a new parent
        local newChild = AABBTree()
        newChild:setLeaf(parentNode.data)
        newChild:updateAABB()

        parentNode:setBranch(node, newChild)
        parentNode:updateAABB()
    else
        -- parent is branch, add as left or right child
        local aabbL = parentNode.left.aabb
        local aabbR = parentNode.right.aabb
        if aabbL and aabbR and node.aabb then
            local volumeChangeL = volume(union(aabbL, node.aabb)) - volume(aabbL)
            local volumeChangeR = volume(union(aabbR, node.aabb)) - volume(aabbR)
            if volumeChangeL < volumeChangeR then
                AABBTree.insertNode(node, parentNode.left)
            else
                AABBTree.insertNode(node, parentNode.right)
            end

            parentNode:updateAABB()
        end
    end
end

function AABBTree:setLeaf(data)
    self.data = data
    data.treeNode = self

    self.left = nil
    self.right = nil

    self.isLeaf = true
end

function AABBTree:setBranch(nodeL, nodeR)
    nodeL.parent = self
    nodeR.parent = self

    self.left = nodeL
    self.right = nodeR

    self.data = nil

    self.isLeaf = false
end

function AABBTree:remove(data)
    local node = data.treeNode
    if not node then
        return
    end

    --node.data = nil
    data.treeNode = nil

    self:removeNode(node)
end

function AABBTree:removeNode(node)
    local parent = node.parent
    if not parent then
        -- root node
        return
    end

    local nodeAside = node:getNodeAside()
    if not nodeAside then
        return
    end

    if parent.parent then
        nodeAside.parent = parent.parent
        if parent == parent.parent.left then
            parent.parent.left = nodeAside
        elseif parent == parent.parent.right then
            parent.parent.right = nodeAside
        end
    else
        -- no grandparent, set root to node aside
        self.data = nodeAside.data
        self.left = nodeAside.left
        self.right = nodeAside.right
        self.isLeaf = nodeAside.isLeaf

        self:updateAABB()
    end
end

function AABBTree:updateAABB()
    if self.isLeaf then
        -- update aabb by data's aabb
        if self.data and self.data.aabb then
            self.aabb = {self.data.aabb[1] - fatMargin, self.data.aabb[2] + fatMargin,
                         self.data.aabb[3] - fatMargin, self.data.aabb[4] + fatMargin}
        end
    else
        self.aabb = union(self.left.aabb, self.right.aabb)
    end
end

function AABBTree:getNodeAside()
    if self.parent then
        if self == self.parent.left then
            return self.parent.right
        elseif self == self.parent.right then
            return self.parent.left
        end
    end

    return nil
end

function AABBTree:computeCollide()
    if self.isLeaf == true then
        return
    end

    self:clearCrossFlag()

    local list = {}

    self:computeCollideNode(self.left, self.right, list)
end

function AABBTree:updateTreeNode()
    if self.isLeaf == true then
        self:updateAABB()
    else
        local list = {}
        self:getNodeOutBound(list)

        for k,node in pairs(list) do
            local parent = node.parent
            local nodeAside = node:getNodeAside()

            if parent.parent then
                nodeAside.parent = parent.parent
                if parent == parent.parent.left then
                    parent.parent.left = nodeAside
                elseif parent == parent.parent.right then
                    parent.parent.right = nodeAside
                end
            else
                -- no grandparent, set root to node aside
                self.data = nodeAside.data
                self.left = nodeAside.left
                self.right = nodeAside.right
                self.isLeaf = nodeAside.isLeaf

                self:updateAABB()
            end
            
            node:updateAABB()
            self:insert(node.data)
        end
    end
end

function AABBTree:getNodeOutBound()
    local list = {}

    local pre
    local current = self

    while (current) do
        if not current.left then
            if current.isLeaf then
                local aabbFat = current.aabb
                local aabbData = current.data.aabb
                if isOut(aabbData, aabbFat) then
                    table.insert(list, current)
                end
            end

            current = current.right
        else
            pre = current.left
            while (pre.right and pre.right ~= current) do
                pre = pre.right
            end

            if not pre.right then
                pre.right = current
                current = current.left
            else
                pre.right = nil
                current = current.right
            end
        end
    end

    return list
end

-- clear cross flag and set all leaf's xCollide/yCollide to false
function AABBTree:clearCrossFlag()
    local pre
    local current = self

    while (current) do
        if not current.left then
            if current.isLeaf then
                current.childCrossed = false
            end

            current = current.right
        else
            pre = current.left
            while (pre.right and pre.right ~= current) do
                pre = pre.right
            end

            if not pre.right then
                pre.right = current
                current = current.left
            else
                pre.right = nil
                current.childCrossed = false
                current = current.right
            end
        end
    end
end

function AABBTree:crossChildren(list)
    if not self.childCrossed then
        self:computeCollideNode(self.left, self.right, list)
        self.childCrossed = true
    end
end

function AABBTree:computeCollideNode(nodeL, nodeR, list)
    if nodeL.isLeaf then
        if nodeR.isLeaf then

            table.insert(list, {nodeL, nodeR})

            -- two leaf, check for collide
            if nodeL.data and nodeR.data then
                nodeL.data:checkJoint(nodeR.data)
            end
        else
            -- one leaf, one branch
            nodeR:crossChildren(list)
            self:computeCollideNode(nodeL, nodeR.left, list)
            self:computeCollideNode(nodeL, nodeR.right, list)
        end
    else
        if nodeR.isLeaf then
            nodeL:crossChildren(list)
            self:computeCollideNode(nodeL.left, nodeR, list)
            self:computeCollideNode(nodeL.right, nodeR, list)
        else
            -- two branches
            nodeL:crossChildren(list)
            nodeR:crossChildren(list)
            self:computeCollideNode(nodeL.left, nodeR.left, list)
            self:computeCollideNode(nodeL.left, nodeR.right, list)
            self:computeCollideNode(nodeL.right, nodeR.left, list)
            self:computeCollideNode(nodeL.right, nodeR.right, list)
        end
    end
end

function AABBTree:toString()
    print("___________________________")
    local queue = {}
    local results = {}
    table.insert(queue, self)

    while queue[1] do
        local dequeued = table.remove(queue, 1)
        table.insert(results, dequeued)
        if dequeued.left then
            table.insert(queue, dequeued.left)
        end
        if dequeued.right then
            table.insert(queue, dequeued.right)
        end
    end

    local as_strings = {}
    for i, v in ipairs(results) do
        --print("v:",v)
        --table.insert(as_strings, tostring(v))
        if v.isLeaf then
            print("*****leaf:{"..v.aabb[1]..","..v.aabb[2]..","..v.aabb[3]..","..v.aabb[4].."}")
        else
            print("&&&&&branch:{"..v.aabb[1]..","..v.aabb[2]..","..v.aabb[3]..","..v.aabb[4].."}")
        end
    end

    print("_________________________end")
    --return table.concat(as_strings, " ")
end

return AABBTree
