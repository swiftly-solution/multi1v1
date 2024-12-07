local WeaponsObjects = {}
local WeaponNames = {}

function GunsCommand(playerid, args, argc, silent)
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:IsValid() then return end

    player:HideMenu()
    player:ShowMenu("guns_main_menu")
end

commands:Register("gunsmenu", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:IsValid() then return end

    if argc < 1 then return end
    local category_name = args[1]
    if not WeaponsObjects[category_name] then return end

    local menuid = "guns_menu_selectweapon_"..GetTime()
    menus:RegisterTemporary(menuid, FetchTranslation("multi1v1.menu.guns."..category_name..".title"), config:Fetch("multi1v1.color"), WeaponsObjects[category_name])
    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("gunsmenu_weapon", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:IsValid() then return end

    if argc < 1 then return end
    local weapon_name = args[1]
    if not WeaponNames[weapon_name] then return end

    local teamsTbl = {}
    if config:Exists("multi1v1.weapons."..WeaponNames[weapon_name][2]..".ct."..weapon_name) then table.insert(teamsTbl, { "[" .. ((exports["cookies"]:GetPlayerCookie(playerid, "multi1v1.guns."..WeaponNames[weapon_name][2]..".ct") == weapon_name) and "✔️" or "❌") .. "] " .. FetchTranslation("multi1v1.menu.ct"), "sw_gunsmenu_selectweapon "..weapon_name.." ct" }) end
    if config:Exists("multi1v1.weapons."..WeaponNames[weapon_name][2]..".t."..weapon_name)  then table.insert(teamsTbl, { "[" .. ((exports["cookies"]:GetPlayerCookie(playerid, "multi1v1.guns."..WeaponNames[weapon_name][2]..".t") == weapon_name) and "✔️" or "❌") .. "] "  .. FetchTranslation("multi1v1.menu.t"), "sw_gunsmenu_selectweapon "..weapon_name.." t" }) end

    local menuid = "guns_menu_weapon_"..GetTime()
    menus:RegisterTemporary(menuid, WeaponNames[weapon_name][1] .. " - ".. FetchTranslation("multi1v1.menu.guns."..WeaponNames[weapon_name][2]..".title"), config:Fetch("multi1v1.color"), teamsTbl)
    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("gunsmenu_selectweapon", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player then return end
    if not player:IsValid() then return end

    if argc < 2 then return end
    local weapon_name = args[1]
    local team = args[2]

    if not WeaponNames[weapon_name] then return end
    if team ~= "ct" and team ~= "t" then return end

    local alreadyEquipped = (exports["cookies"]:GetPlayerCookie(playerid, "multi1v1.guns."..WeaponNames[weapon_name][2].."."..team) == weapon_name)
    
    if alreadyEquipped then
        exports["cookies"]:SetPlayerCookie(playerid, "multi1v1.guns."..WeaponNames[weapon_name][2].."."..team, nil)
    else
        exports["cookies"]:SetPlayerCookie(playerid, "multi1v1.guns."..WeaponNames[weapon_name][2].."."..team, weapon_name)
    end

    ReplyToCommand(playerid, config:Fetch("multi1v1.prefix"),
        FetchTranslation(alreadyEquipped and "multi1v1.unequip" or "multi1v1.equip"):gsub("{NAME}", WeaponNames[weapon_name][1]):gsub(
            "{TEAM}", FetchTranslation("multi1v1.menu." .. team)))

    player:ExecuteCommand("sw_gunsmenu_weapon "..weapon_name)
end)

AddEventHandler("OnPluginStart", function (event)
    local cmds = config:Fetch("multi1v1.guns_commands")
    for i=1,#cmds do
        commands:Register(cmds[i], GunsCommand)
    end

    menus:Register("guns_main_menu", FetchTranslation("multi1v1.menu.guns.title"), config:Fetch("multi1v1.color"), {
        { FetchTranslation("multi1v1.menu.guns.rifles"), "sw_gunsmenu rifles" },
        { FetchTranslation("multi1v1.menu.guns.pistols"), "sw_gunsmenu pistols" },
        { FetchTranslation("multi1v1.menu.round_preferences.title"), "sw_roundprefs" }
    })

    local loaded = {}
    local weaps = config:Fetch("multi1v1.weapons")
    for k,v in next,weaps,nil do
        WeaponsObjects[k] = {}
        for k2,v2 in next,v["t"],nil do
            if not loaded[k2] then
                loaded[k2] = true
                table.insert(WeaponsObjects[k], { v2, "sw_gunsmenu_weapon "..k2 })
                WeaponNames[k2] = { v2, k }
            end
        end
        for k2,v2 in next,v["ct"],nil do
            if not loaded[k2] then
                loaded[k2] = true
                table.insert(WeaponsObjects[k], { v2, "sw_gunsmenu_weapon "..k2 })
                WeaponNames[k2] = { v2, k }
            end
        end
    end
end)

AddEventHandler("OnAllPluginsLoaded", function (event)
    exports["cookies"]:RegisterCookie("multi1v1.guns.rifles.ct", "weapon_m4a1")
    exports["cookies"]:RegisterCookie("multi1v1.guns.rifles.t", "weapon_ak47")
    exports["cookies"]:RegisterCookie("multi1v1.guns.pistols.ct", "weapon_hkp2000")
    exports["cookies"]:RegisterCookie("multi1v1.guns.pistols.t", "weapon_glock")
end)