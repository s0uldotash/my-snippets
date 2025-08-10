local key = 316 -- PG UP
local notKilled = true
local showMenu = false
local selected = 1
local inputBuffer = ""
local options = {
    { name = "Heal", func = function() TriggerEvent('txcl:heal') end },
    { name = "Clear Area", input = "Radius", func = function(val) TriggerEvent('txcl:clearArea', tonumber(val)) end },
    { name = "Set Frozen", input = "true/false", func = function(val) TriggerEvent('txcl:setFrozen', val == "true") end },
    { name = "TP to Coords", input = "x y z", func = function(val)
        local x, y, z = val:match("([^%s]+) ([^%s]+) ([^%s]+)")
        if x and y and z then
            TriggerEvent('txcl:tpToCoords', tonumber(x), tonumber(y), tonumber(z))
        end
    end },
    { name = "TP to Waypoint", func = function() TriggerEvent('txcl:tpToWaypoint') end },
    { name = "Show IDs", input = "true/false", func = function(val) TriggerEvent('txcl:showPlayerIDs', val == "true") end },
    { name = "Boost Vehicle", func = function() TriggerEvent('txcl:vehicle:boost') end },
    { name = "Fix Vehicle", func = function() TriggerEvent('txcl:vehicle:fix') end },
    { name = "Seat in Vehicle", input = "netID seat flags", func = function(val)
        local a, b, c = val:match("([^%s]+) ([^%s]+) ([^%s]+)")
        if a and b and c then
            TriggerEvent('txcl:seatInVehicle', tonumber(a), tonumber(b), tonumber(c))
        end
    end },
    { name = "Kill Menu", func = function() notKilled = false end },
}
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, key) then
            showMenu = not showMenu
        end
    end
end)
local function GetUserInput(windowTitle, defaultText, maxLength)
    AddTextEntry('FMMC_KEY_TIP1', windowTitle)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", defaultText or "", "", "", "", maxLength or 30)
    while UpdateOnscreenKeyboard() == 0 do
        Citizen.Wait(5)
    end
    if UpdateOnscreenKeyboard() == 1 then
        return GetOnscreenKeyboardResult()
    end
    return nil
end
Citizen.CreateThread(function()
    while notKilled do
        Citizen.Wait(0)
        if showMenu then
            local titleX, titleY = 0.1, 0.2 - 0.02
            local titleW, titleH = 0.3, 0.04
            DrawRect(titleX + titleW/2, titleY + titleH/2, titleW, titleH, 50, 50, 200, 220)
            DrawText3D(titleX + 0.005, titleY + titleH/2 - 0.017, "txAbuser (FUCK TX ADMIN)")
            local w, h = 0.3, 0.035
            local x, y = 0.1, 0.2
            for i, opt in ipairs(options) do
                DrawRect(x + w/2, y + (i * h), w, h, i == selected and 100 or 30, 30, 30, 180)
                DrawText3D(x + 0.005, y + (i * h) - 0.017, opt.name .. (opt.input and " [INPUT]" or ""))
            end
            if IsControlJustPressed(0, 172) then
                selected = selected - 1 if selected < 1 then selected = #options end
            elseif IsControlJustPressed(0, 173) then
                selected = selected + 1 if selected > #options then selected = 1 end
            elseif IsControlJustPressed(0, 191) then
                local opt = options[selected]
                if opt.input then
                    local keyboard = GetUserInput(opt.input, "", 20)
                    if keyboard then opt.func(keyboard) end
                else
                    opt.func()
                end
            end
        end
    end
end)
function DrawText3D(x, y, text)
    SetTextFont(0)
    SetTextScale(0.3, 0.3)
    SetTextColour(255, 255, 255, 255)
    SetTextWrap(0.0, 1.0)
    SetTextCentre(false)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end
