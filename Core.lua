-- BiSWishAddon Core Module
local addonName, ns = ...

-- Core namespace
ns.Core = ns.Core or {}

-- Database structure
BiSWishAddonDB = BiSWishAddonDB or {
    items = {}, -- itemID -> {name, players = {player1, player2, ...}}
    version = 1
}

-- Initialize core system
function ns.Core.Initialize()
    print("|cff39FF14BiSWishAddon|r: Core system initialized!")
end
