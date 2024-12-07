Queue = {}

function Queue:new()
    local obj = {
        first = 1,
        last = 0,
        items = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Queue:enqueue(item)
    for k,v in next,self.items,nil do
        if v == item then return end
    end
    self.last = self.last + 1
    self.items[self.last] = item
end

function Queue:dequeue()
    if self.first > self.last then
        return nil
    end
    local item = self.items[self.first]
    self.items[self.first] = nil
    self.first = self.first + 1
    return item
end

function Queue:isEmpty()
    return self.first > self.last
end

function Queue:peek()
    if self:isEmpty() then
        return nil
    end
    return self.items[self.first]
end

function Queue:getItems()
    return self.items
end

function Queue:size()
    return self.last - self.first + 1
end

function Queue:clear()
    self.first = 1
    self.last = 0
    self.items = {}
end

-- Queue Manager
QueueManager = {
    queues = {},
    nextId = 1
}

function QueueManager:createQueue()
    local id = self.nextId
    self.queues[id] = Queue:new()
    self.nextId = self.nextId + 1
    return id
end

function QueueManager:clearQueue(queueId)
    local queue = self.queues[queueId]
    if queue then
        queue:clear()
    end
end

function QueueManager:sizeQueue(queueId)
    local queue = self.queues[queueId]
    if queue then
        return queue:size()
    end
    return nil
end

function QueueManager:peekQueue(queueId)
    local queue = self.queues[queueId]
    if queue then
        return queue:peek()
    end
    return nil
end

function QueueManager:enqueue(queueId, item)
    local queue = self.queues[queueId]
    if queue then
        queue:enqueue(item)
    end
end

function QueueManager:dequeue(queueId)
    local queue = self.queues[queueId]
    if queue then
        return queue:dequeue()
    end
    return nil
end

function QueueManager:isQueueEmpty(queueId)
    local queue = self.queues[queueId]
    if queue then
        return queue:isEmpty()
    end
    return nil
end

function QueueManager:getItems(queueId)
    local queue = self.queues[queueId]
    if queue then
        return queue:getItems()
    end
    return nil
end

function QueueManager:remove(queueId)
    if self.queues[queueId] then
        self.queues[queueId]:clear()
        self.queues[queueId] = nil
        return true
    end
    return false
end
