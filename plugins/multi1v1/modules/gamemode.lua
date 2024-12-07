AddEventHandler("OnRoundStart", function (event, mapname)
    local cvars = config:Fetch("multi1v1.convars")
    for k,v in next,cvars,nil do
        server:Execute(k .. " "..v)
    end
end)