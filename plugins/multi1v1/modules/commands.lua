

commands:Register("enemy", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end

    local opponent = GetOpponent(playerid)

    if opponent then
        local opponentPlayer = GetPlayer(opponent)
        if opponentPlayer then
            ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.facing_off"):gsub("{NAME}", opponentPlayer:CBasePlayerController().PlayerName))
        else
            ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.facing_off"):gsub("{NAME}", "Unknown"))
        end
    else
        ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.no_opponent"))
    end
end)

commands:Register("roundtype", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end

    local arenatype = arenaTypes[playerArena[playerid]]
    ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.round_type"):gsub("{NAME}", GetRoundTypeName(arenatype)))
end)

commands:Register("arena", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end

    local arena = playerArena[playerid]
    ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.in_arena"):gsub("{ARENA}", arena))
end)