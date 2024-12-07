local ArenaSpawns = {}
local waitingQueue = -1
local rankingQueue = -1
local playersToAddQueue = -1

local arenaPlayer1 = {}
local arenaPlayer2 = {}
local arenaWinners = {}
local arenaLosers = {}
arenaTypes = {}
playerArena = {}
local roundEnded = false

AddEventHandler("OnPluginStart", function (event)
    waitingQueue = QueueManager:createQueue()
    rankingQueue = QueueManager:createQueue()
    playersToAddQueue = QueueManager:createQueue()
end)

local function Vector3Distance(v1,v2)
    if type(v1) ~= "userdata" or type(v2) ~= "userdata" then
        error("Vectors not correctly.")
    end
    local dx = v2.x - v1.x
    local dy = v2.y - v1.y
    local dz = v2.z - v1.z

    return #Vector(dx, dy, dz)
end

local function findClosestSpawn(spawns, numSpawns, coords)
    local closestDistance = 999999999
    local closestIndex = -1

    for i=1,numSpawns do
        local crds = CBaseEntity(spawns[i]:ToPtr()).CBodyComponent.SceneNode.AbsOrigin
        if Vector3Distance(crds, coords) < closestDistance then
            closestDistance = Vector3Distance(crds, coords)
            closestIndex = i
        end
    end

    return closestIndex
end

AddEventHandler("OnMapLoad", function (event, mapName)
    for i=1,#ArenaSpawns do
        ArenaSpawns[i] = nil
    end
    QueueManager:clearQueue(waitingQueue)
end)

AddEventHandler("OnPlayerConnectFull", function(event)
    local player = GetPlayer(event:GetInt("userid"))
    if not player then return end

    player:SwitchTeam(Team.Spectator)
    QueueManager:enqueue(waitingQueue, player:GetSlot())

    if GetCCSGameRules().WarmupPeriod then
        SetTimeout(1000, function ()
            server:Execute("mp_warmup_end")
        end)
    end

    return EventResult.Continue
end)

AddEventHandler("OnPlayerTeam", function (event)
    event:SetBool("silent", true)
end)

local function addPlayerToQueue(playerid, checkspec)
    if playerid == nil then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:CBaseEntity():IsValid() then return end
    if checkspec or player:CBaseEntity().TeamNum ~= Team.Spectator then
        local hasSpace = (QueueManager:sizeQueue(rankingQueue) < 2 * #ArenaSpawns)
        if hasSpace then
            QueueManager:enqueue(rankingQueue, playerid)
        end
    end
end

local function SetupPlayerSpawn(playerid, arena, spawnidx)
    local player = GetPlayer(playerid)
    if not player then return end

    local base = CBaseEntity(player:CCSPlayerPawn():ToPtr())
    if not base:IsValid() then return end

    player:SwitchTeam(spawnidx + 1)

    player:Respawn()
    base:Teleport(ArenaSpawns[arena][spawnidx][1], ArenaSpawns[arena][spawnidx][2], Vector(0.0,0.0,0.0))

    player:CCSPlayerController().Clan = string.format("Arena %d |", arena)

    local opponent = GetOpponent(playerid)

    local arenatype = arenaTypes[playerArena[playerid]]
    ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.round_type"):gsub("{NAME}", GetRoundTypeName(arenatype)))
    player:ExecuteCommand("sw_arena")

    if opponent ~= nil then
        local opponentPlayer = GetPlayer(opponent)
        if opponentPlayer then
            ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.facing_off"):gsub("{NAME}", opponentPlayer:CBasePlayerController().PlayerName))
        else
            ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.facing_off"):gsub("{NAME}", "Unknown"))
        end
    else
        ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.no_opponent"))
    end
end

AddEventHandler("OnRoundPrestart", function (event)
    if #ArenaSpawns == 0 then
        local tSpawns = FindEntitiesByClassname("info_player_terrorist")
        local ctSpawns = FindEntitiesByClassname("info_player_counterterrorist")
        local numSpawns = ((#tSpawns - #ctSpawns < 0) and #tSpawns or #ctSpawns)

        for i=1,numSpawns do
            local tSpawnScene = CBaseEntity(tSpawns[i]:ToPtr()).CBodyComponent.SceneNode
            local tSpawnPos = tSpawnScene.AbsOrigin
            local tSpawnRot = tSpawnScene.AbsRotation

            local ctSpawnIdx = findClosestSpawn(ctSpawns, numSpawns, tSpawnPos)
            if ctSpawnIdx ~= -1 then
                local ctSpawnScene = CBaseEntity(ctSpawns[ctSpawnIdx]:ToPtr()).CBodyComponent.SceneNode
                table.insert(ArenaSpawns, { { tSpawnPos, tSpawnRot }, { ctSpawnScene.AbsOrigin, ctSpawnScene.AbsRotation } })
            end
        end
    end

    QueueManager:clearQueue(rankingQueue)

    local maxArenas = #ArenaSpawns
    roundEnded = false

    for i=0,playermanager:GetPlayerCap()-1,1 do
        playerArena[i] = nil
    end

    addPlayerToQueue(arenaWinners[1])
    addPlayerToQueue(arenaWinners[2])

    for i=2,maxArenas-1 do
        addPlayerToQueue(arenaLosers[i - 1])
        addPlayerToQueue(arenaWinners[i + 1])
    end

    if maxArenas >= 2 then
        addPlayerToQueue(arenaLosers[maxArenas - 1])
        addPlayerToQueue(arenaLosers[maxArenas])
    end

    while ((QueueManager:sizeQueue(rankingQueue) + QueueManager:sizeQueue(playersToAddQueue) < 2 * maxArenas) and (QueueManager:sizeQueue(waitingQueue) > 0)) do
        local playerid = QueueManager:dequeue(waitingQueue)
        QueueManager:enqueue(playersToAddQueue, playerid)
    end

    while QueueManager:sizeQueue(playersToAddQueue) > 0 do
        local playerid = QueueManager:dequeue(playersToAddQueue)
        addPlayerToQueue(playerid, true)
    end

    local specs = QueueManager:getItems(waitingQueue)
    local queuepos = 0
    for _,v in next,specs,nil do
        queuepos = queuepos + 1
        ReplyToCommand(v, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.arenas_full"):gsub("{ARENA_COUNT}", maxArenas):gsub("{QUEUE_POS}", queuepos))
    end

    for i=1,maxArenas do
        arenaPlayer1[i] = -1
        arenaPlayer2[i] = -1
    end

    for i=1,maxArenas do
        local player1 = QueueManager:dequeue(rankingQueue)
        local player2 = QueueManager:dequeue(rankingQueue)

        arenaPlayer1[i] = player1
        arenaPlayer2[i] = player2
        arenaTypes[i] = GetRoundType(player1, player2)
        if player1 ~= nil and player1 ~= -1 then playerArena[player1] = i end
        if player2 ~= nil and player2 ~= -1 then playerArena[player2] = i end
    end

    for i=1,maxArenas do
        arenaWinners[i] = -1
        arenaLosers[i] = -1
    end
end)

function GetOpponent(playerid)
    if playerArena[playerid] then
        if arenaPlayer1[playerArena[playerid]] == playerid then
            return arenaPlayer2[playerArena[playerid]]
        else
            return arenaPlayer1[playerArena[playerid]]
        end
    end
end

AddEventHandler("OnClientDisconnect", function(event, playerid)
    local arena = playerArena[playerid]
    if arena then
        local p1 = arenaPlayer1[arena]
        local p2 = arenaPlayer2[arena]

        local hasp1 = (IsPlayerActive(p1) and p1 ~= playerid)
        local hasp2 = (IsPlayerActive(p2) and p2 ~= playerid)

        if hasp1 and not hasp2 then
            arenaWinners[arena] = p1
            arenaLosers[arena] = p2
        else
            arenaWinners[arena] = p2
            arenaLosers[arena] = p1
        end
        ReplyToCommand(arenaWinners[arena] or -1, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.opponent_left"))
        playerArena[playerid] = nil
    end
end)

function IsPlayerActive(playerid)
    if playerid == nil then return false end
    local player = GetPlayer(playerid)
    if not player then return false end
    if not player:CBaseEntity():IsValid() then return false end
    return ((player:CBaseEntity().TeamNum == Team.CT) or (player:CBaseEntity().TeamNum == Team.T))
end

function IsPlayerAlive(playerid)
    if playerid == nil then return false end
    local player = GetPlayer(playerid)
    if not player then return false end
    if not player:CBaseEntity():IsValid() then return false end
    return (player:CBaseEntity().LifeState == LifeState_t.LIFE_ALIVE)
end

AddEventHandler("OnRoundEnd", function (event)
    roundEnded = true

    local maxArenas = #ArenaSpawns
    for i=1,maxArenas do
        local player1 = arenaPlayer1[i]
        local player2 = arenaPlayer2[i]
        if arenaWinners[i] == -1 then
            arenaWinners[i] = player1
            arenaLosers[i] = player2
        end
    end
end)

AddEventHandler("OnPlayerDeath", function (event)
    local deadPlayerID = event:GetInt("userid")
    local alivePlayerID = event:GetInt("attacker")
    local deadPlayer = GetPlayer(deadPlayerID)
    local alivePlayer = GetPlayer(alivePlayerID)

    if not deadPlayer then return end

    local arena = playerArena[deadPlayerID]
    if arena == nil then return end

    if not alivePlayer or alivePlayerID == deadPlayerID then
        local p1 = arenaPlayer1[arena]
        local p2 = arenaPlayer2[arena]

        if deadPlayerID == p1 then
            arenaWinners[arena] = p2
            arenaLosers[arena] = p1
        else
            arenaWinners[arena] = p1
            arenaLosers[arena] = p2
        end
    else
        arenaWinners[arena] = alivePlayerID
        arenaLosers[arena] = deadPlayerID
    end
end)

AddEventHandler("OnPostRoundStart", function (event)
    local refreshEvent = Event("OnNextlevelChanged")

    for i=0,playermanager:GetPlayerCap()-1,1 do
        if GetPlayer(i) then
            if playerArena[i] ~= nil then
                if arenaPlayer1[playerArena[i]] == i then
                    SetupPlayerSpawn(i, playerArena[i], 1)
                else
                    SetupPlayerSpawn(i, playerArena[i], 2)
                end
            end

            refreshEvent:FireEventToClient(i)
        end
    end
end)

AddEventHandler("OnPlayerSpawn", function (event)
    local playerid = event:GetInt("userid")
    if not IsPlayerActive(playerid) then return end
    if playerArena[playerid] ~= nil then
        local arenatype = arenaTypes[playerArena[playerid]]

        GivePlayerArenaTypeWeapons(playerid, arenatype)
    else
        local player = GetPlayer(playerid)
        if not player then return end

        player:ChangeTeam(Team.Spectator)
        QueueManager:enqueue(waitingQueue, playerid)
    end
end)

SetTimer(1000, function ()
    if roundEnded then return end

    local maxArenas = #ArenaSpawns
    local activePlayers = 0
    local doneChecking = true

    for i=1,maxArenas do
        local player1 = arenaPlayer1[i]
        local player2 = arenaPlayer2[i]

        if IsPlayerActive(player1) then activePlayers = activePlayers + 1 end
        if IsPlayerActive(player2) then activePlayers = activePlayers + 1 end

        if player1 == -1 then arenaWinners[i] = player2 end
        if player2 == -1 then arenaWinners[i] = player1 end

        if player1 ~= -1 and player2 ~= -1 and IsPlayerAlive(player1) and not IsPlayerAlive(player2) then
            arenaWinners[i] = player1
            arenaLosers[i] = player2
        end

        if player1 ~= -1 and player2 ~= -1 and not IsPlayerAlive(player1) and IsPlayerAlive(player2) then
            arenaWinners[i] = player2
            arenaLosers[i] = player1
        end

        if arenaWinners[i] == -1 and player1 ~= -1 and player2 ~= -1 and player1 ~= nil and player2 ~= nil then
            doneChecking = false
            break
        end
    end

    local finished = (doneChecking and activePlayers >= 2)
    local waitingPlayers = (activePlayers < 2 and QueueManager:sizeQueue(waitingQueue) > 0)

    if finished or waitingPlayers then
        server:TerminateRound(convar:Get("mp_round_restart_delay"), RoundEndReason_t.TerroristsWin)
    end
end)