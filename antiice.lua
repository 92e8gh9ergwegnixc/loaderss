-- ANTI ICE (toggle via State.AntiIce)
-- Ejecuta en loop cada 0.9s mientras Internal.MainAlive

task.spawn(function()
    while Internal.MainAlive do
        if State.AntiIce then
            pcall(function()
                local iceBin = game:GetService("Workspace"):FindFirstChild("IceBin")
                if iceBin and iceBin:FindFirstChild("is_ice") then
                    iceBin.is_ice:Destroy()
                    Utils:SetStatus(statusLabel, "[DEBUG] Deleted: IceBin.is_ice", 1.8)
                end
            end)
        end
        if not Internal.MainAlive then break end
        task.wait(0.9)
    end
end)
