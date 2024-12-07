if not config:Exists("multi1v1.round_types.normal") then
    print("[{red}ERROR{default}] The {red}normal{default} round type doesn't exists. Please create it in `addons/swiftly/configs/plugins/multi1v1.json`.")
    return error("The normal round type doesn't exists")
end

--- @param tbl table
--- @param element any
--- @return boolean
function table.contains(tbl, element)
    for i=1,#tbl do
        if tbl[i] == element then
            return true
        end
    end

    return false
end

commands:Register("roundprefs", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:IsValid() then return end

    local roundPrefsOptions = {}
    local round_types = config:Fetch("multi1v1.round_types")
    for k,v in next,round_types,nil do
        table.insert(roundPrefsOptions, { "[" .. (table.contains(exports["cookies"]:GetPlayerCookie(playerid, "multi1v1.round.preferences"), k) and "✔️" or "❌") .. "] "  ..  v.display, "sw_selectroundprefs "..k })
    end

    local menuid = "round_perfs_pl_"..GetTime()
    menus:RegisterTemporary(menuid, FetchTranslation("multi1v1.menu.round_preferences.title"), config:Fetch("multi1v1.color"), roundPrefsOptions)

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("selectroundprefs", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:IsValid() then return end

    if argc < 1 then return end
    local round_type = args[1]
    if not config:Exists("multi1v1.round_types."..round_type) then return end

    local prefs = exports["cookies"]:GetPlayerCookie(playerid, "multi1v1.round.preferences")

    if table.contains(prefs, round_type) then
        if #prefs <= 1 then
            return ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.needs_minimum_one_preference"))
        end

        for i=1,#prefs do
            if prefs[i] == round_type then
                table.remove(prefs, i)
                break
            end
        end

        ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.unequip_rtype"):gsub("{NAME}", config:Fetch("multi1v1.round_types."..round_type..".display")))
    else
        table.insert(prefs, round_type)

        ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"), FetchTranslation("multi1v1.equip_rtype"):gsub("{NAME}", config:Fetch("multi1v1.round_types."..round_type..".display")))
    end
    exports["cookies"]:SetPlayerCookie(playerid, "multi1v1.round.preferences", prefs)

    player:ExecuteCommand("sw_roundprefs")
end)

--- @param player1 number
--- @param player2 number
--- @return string
function GetRoundType(player1, player2)
    if player1 == -1 or player2 == -1 then return "normal" end
    local player1Prefs = exports["cookies"]:GetPlayerCookie(player1, "multi1v1.round.preferences") or {"normal"}
    local player2Prefs = exports["cookies"]:GetPlayerCookie(player2, "multi1v1.round.preferences") or {"normal"}

    local sharedPrefs = {}
    for i=1,#player1Prefs do
        if table.contains(player2Prefs, player1Prefs[i]) then
            table.insert(sharedPrefs, player1Prefs[i])
        end
    end

    for i=#sharedPrefs,1,-1 do
        if not config:Exists("multi1v1.round_types."..sharedPrefs[i]) then
            table.remove(sharedPrefs, i)
        end
    end

    if #sharedPrefs == 0 then table.insert(sharedPrefs, "normal") end

    math.randomseed(server:GetTickCount())
    local randidx = math.random(1,#sharedPrefs)

    return (sharedPrefs[randidx] or "normal")
end

function GetRoundTypeName(rtype)
    if not config:Exists("multi1v1.round_types."..rtype) then return config:Fetch("multi1v1.round_types.normal.display") end
    return config:Fetch("multi1v1.round_types."..rtype..".display")
end

function RemoveByClassname(weaponmanager, classname)
    local weapons = weaponmanager:GetWeapons()
    for i = 1, #weapons do
        --- @type Weapon
        local weapon = weapons[i]
        if CBaseEntity(weapon:CBasePlayerWeapon():ToPtr()).Parent.Entity.DesignerName == classname then
            weapon:Remove()
            break
        end
    end
end

function GivePlayerArenaTypeWeapons(playerid, arenatype)
    if not IsPlayerAlive(playerid) then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:CBaseEntity():IsValid() then return end

    local teamstr = (player:CBaseEntity().TeamNum == Team.CT and "ct" or "t")

    local round_type_settings = config:Fetch("multi1v1.round_types."..arenatype)
    local weaponmanager = player:GetWeaponManager()
    weaponmanager:RemoveWeapons()

    if round_type_settings.rifle == true then
        weaponmanager:GiveWeapon(exports["cookies"]:GetPlayerCookie(playerid, "multi1v1.guns.rifles."..teamstr))
    elseif type(round_type_settings.rifle) == "string" then
        weaponmanager:GiveWeapon(round_type_settings.rifle)
    end

    if round_type_settings.pistol == true then
        weaponmanager:GiveWeapon(exports["cookies"]:GetPlayerCookie(playerid, "multi1v1.guns.pistols."..teamstr))
    elseif type(round_type_settings.pistol) == "string" then
        weaponmanager:GiveWeapon(round_type_settings.pistol)
    end

    if not player:CCSPlayerPawn():IsValid() then return end
    player:CCSPlayerPawn().ArmorValue = round_type_settings.armor

    if round_type_settings.knife == false then
        local weapons = weaponmanager:GetWeapons()
        for i = 1, #weapons do
            --- @type Weapon
            local weapon = weapons[i]
            if weapon:CCSWeaponBaseVData().GearSlot == gear_slot_t.GEAR_SLOT_KNIFE then
                weapon:Remove()
                break
            end
        end
    else
        weaponmanager:GiveWeapon("weapon_knife")
    end

    if round_type_settings.zeus == true then
        weaponmanager:GiveWeapon("weapon_taser")
    end

    if round_type_settings.grenades.incendiary == true then
        weaponmanager:GiveWeapon("weapon_incgrenade")
    end

    if round_type_settings.grenades.flashbang == true then
        weaponmanager:GiveWeapon("weapon_flashbang")
    end

    if round_type_settings.grenades.he == true then
        weaponmanager:GiveWeapon("weapon_hegrenade")
    end

    if round_type_settings.grenades.smoke == true then
        weaponmanager:GiveWeapon("weapon_smokegrenade")
    end

    if round_type_settings.grenades.decoy == true then
        weaponmanager:GiveWeapon("weapon_decoy")
    end

    if round_type_settings.grenades.ta == true then
        weaponmanager:GiveWeapon("weapon_tagrenade")
    end
end

AddEventHandler("OnAllPluginsLoaded", function (event)
    exports["cookies"]:RegisterCookie("multi1v1.round.preferences", {"normal", "knife", "pistol", "awp", "ssg"})
end)