-- ANTI BUS (toggle via State.AntiBusEnabled)
-- Ejecuta en loop cada 0.18s mientras Internal.MainAlive

task.spawn(function()
    while Internal.MainAlive do
        if State.AntiBusEnabled then
            local bus = game:GetService("Workspace"):FindFirstChild("BusModel")
            if bus then
                pcall(function() bus:Destroy() end)
                Utils:SetStatus(statusLabel, "[DEBUG] BusModel eliminado (Anti Bus)", 2.2)
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.18)
    end
end)
