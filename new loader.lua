-- Roblox Loader con keywords (World / City) + PlaceId

local placeLoaders = {
    [14184086618] = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/rideabike.lua", -- Ride a Bike
    [7979341445]  = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/EZ.lua",
    [6403373529]  = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/sblegiteh4.lua",
    [18406461316] = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/1year.lua",
    [12062249395] = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/inf.lua",
    [7809570930]  = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/difffling.lua",
    [123741668193208] = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/the%201m%20rope.lua",
    [12804948086] = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/the%20craziest%20game%20ever.lua",
    [84890467483013] = "https://raw.githubusercontent.com/92e8gh9ergwegnixc/loaderss/refs/heads/main/spot%20the%20differences.lua"
}

-- Detecta nombre del juego
local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:lower()
local url

-- Keywords que disparan el script de la bici
local keywords = { "world", "City" }

local matched = false
for _, word in ipairs(keywords) do
    if string.find(placeName, word) then
        url = placeLoaders[14184086618]
        matched = true
        break
    end
end

-- Si no matchea keywords, busca por PlaceId
if not matched then
    url = placeLoaders[game.PlaceId]
end

if url then
    local success, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("⚠️ Error al cargar script: " .. tostring(err))
    end
else
    warn("❌ No loader mapeado para este juego/place: " .. tostring(game.PlaceId) .. " (" .. placeName .. ")")
end
