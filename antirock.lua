-- ANTI ROCK (toggle via State.AntiRock)
-- Escanea todo Workspace y elimina partes con "rock" en el nombre cada 0.8s

task.spawn(function()
    while Internal.MainAlive do
        if State.AntiRock then
            for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
                if not Internal.MainAlive then break end
                if obj:IsA("BasePart") and tostring(obj.Name):lower():find("rock") then
                    pcall(function() obj:Destroy() end)
                    Utils:SetStatus(statusLabel, "[DEBUG] Deleted: " .. tostring(obj.Name), 1.8)
                end
            end
        end
        if not Internal.MainAlive then break end
        task.wait(0.8)
    end
end)
