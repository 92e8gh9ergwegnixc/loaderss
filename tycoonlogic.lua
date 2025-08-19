-- AUTO REMOVE TYCOON / DROPPER / WEDGE / FORCE PARTS
-- Runs constantly every 0.001s

task.spawn(function()
    local keywords = { "tycoon", "dropper", "wedge", "force", "Building" }
    while task.wait(0.001) do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart") then
                local lowerName = tostring(obj.Name):lower()
                for _, kw in ipairs(keywords) do
                    if lowerName:find(kw) then
                        -- safely destroy
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
