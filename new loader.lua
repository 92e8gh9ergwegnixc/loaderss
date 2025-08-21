-- Roblox Multi-Game Loader (UniverseId only)

local universeLoaders = {
    [3845366720]   = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/rideabike.lua", -- Ride a Bike
    [2689745385]   = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/EZ.lua",
    [1210921061]   = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/sblegiteh4.lua",
    [10749683936]  = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/1year.lua",
    [9250082598]   = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/inf.lua",
    [5401793871]   = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/difffling.lua",
    [34823097432]  = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/the%201m%20rope.lua",
    [6734982165]   = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/the%20craziest%20game%20ever.lua",
    [98645328401]  = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/spot%20the%20differences.lua"
}

local universeId = game.GameId
local url = universeLoaders[universeId]

if url then
    local success, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("⚠️ Error al cargar script para UniverseId " .. tostring(universeId) .. ": " .. tostring(err))
    end
else
    warn("❌ No hay loader asignado para UniverseId: " .. tostring(universeId))
end
