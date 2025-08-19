-- ANTI BOMB
-- Elimina cada 0.1s cualquier objeto llamado "bomb" o "bømb"

task.spawn(function()
    local keywords = { "bomb", "bømb" }
    while task.wait(0.5) do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local lowerName = tostring(obj.Name):lower()
                for _, kw in ipairs(keywords) do
                    if lowerName:find(kw) then
                        pcall(function()
                            obj:Destroy()
                        end)
                        break
                    end
                end
            end
        end
    end
end)
