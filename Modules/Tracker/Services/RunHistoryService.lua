local addonName, addon = ...

addon.RunHistoryService = addon.RunHistoryService or {}

-- C_MythicPlus.GetRunHistory is a comparatively expensive call (it builds and
-- returns a full array of run records); without caching it was being re-fetched
-- and re-sorted from scratch every time a Dashboard/Sidebar panel that reads
-- run history was rendered (i.e. on every tab switch). Cached here and
-- invalidated only when the underlying data can actually change.
local cachedRunHistory = nil

---Returns the player's Mythic+ run history, fetching it from the WoW API
---only once per cache invalidation instead of on every render.
---@return table runHistory
function addon.RunHistoryService:getRuns()
    if not cachedRunHistory then
        cachedRunHistory = C_MythicPlus.GetRunHistory(true, true, true) or {}
    end
    return cachedRunHistory
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    cachedRunHistory = nil
end)
