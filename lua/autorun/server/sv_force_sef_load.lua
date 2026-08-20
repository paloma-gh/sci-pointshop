timer.Simple(0, function()
    if file.Exists("sef_addon/scieffects.lua", "LUA") then
        include("sef_addon/scieffects.lua")
        print("[SCI] scieffects.lua force-loaded.")
    else
        print("[SCI] scieffects.lua not found!")
    end
end)

local function ReloadSEF()
    local function LoadFolder(path)
        local files, _ = file.Find(path .. "/*.lua", "LUA")
        for _, filename in ipairs(files) do
            local fullPath = path .. "/" .. filename
            AddCSLuaFile(fullPath)
            include(fullPath)
            print("[SEF Reload] Loaded: " .. filename)
        end
    end

    LoadFolder("SEF")
    LoadFolder("SEF_Addon")
    LoadFolder("sef_addon")

    for _, ply in ipairs(player.GetAll()) do
        ply:ConCommand("SEF_Reload_Client")
    end
end

local function InitSEFHooks()
    for name, data in pairs(StatusEffects) do
        if data.ServerHooks then
            for _, hookData in ipairs(data.ServerHooks) do
                if hookData.HookType then
                    local hookName = "SEF_SERVER_EFFECT_" .. name .. tostring(data)
                    hook.Add(hookData.HookType, hookName, function(...)
                        hookData.HookFunction(...)
                    end)
                    hookData.HookInit = true
                end
            end
        end
    end

    for name, data in pairs(PassiveEffects) do
        if data.ServerHooks then
            for _, hookData in ipairs(data.ServerHooks) do
                if hookData.HookType and hookData.HookType ~= "" then
                    local hookName = "SEF_SERVER_PASSIVE_" .. name .. tostring(data)
                    hook.Add(hookData.HookType, hookName, function(...)
                        hookData.HookFunction(...)
                    end)
                    hookData.HookInit = true
                end
            end
        end
    end

    print("[SEF] All effect and passive hooks initialized.")
end

timer.Simple(5, ReloadSEF)
timer.Simple(10, InitSEFHooks)
