local addonName, addon = ...

---Formats a duration as "m:ss". Callers own the surrounding presentation:
---the empty/zero placeholder, the colouring, and the sign of a delta — this
---returns the bare number, never a sign, so "+"/"-" callers can prepend their
---own after taking math.abs().
---@param seconds number
---@return string
function addon.formatMinutesSeconds(seconds)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

---Formats a GetServerTime() timestamp as a short localized "time ago" string
---(e.g. "vor 5 Min."), for tooltips that show the freshness of cached/synced
---data (Twinks/Guild keystone views). Returns TIME_UNKNOWN if the timestamp
---is nil (e.g. nothing saved/synced yet this install).
---@param serverTimestamp number|nil
---@return string
function addon.formatRelativeTime(serverTimestamp)
    if not serverTimestamp then
        return addon.locale["TIME_UNKNOWN"]
    end

    local elapsedSeconds = GetServerTime() - serverTimestamp
    if elapsedSeconds < 60 then
        return addon.locale["TIME_JUST_NOW"]
    elseif elapsedSeconds < 3600 then
        return string.format(addon.locale["TIME_MINUTES_AGO"], math.floor(elapsedSeconds / 60))
    elseif elapsedSeconds < 86400 then
        return string.format(addon.locale["TIME_HOURS_AGO"], math.floor(elapsedSeconds / 3600))
    else
        return string.format(addon.locale["TIME_DAYS_AGO"], math.floor(elapsedSeconds / 86400))
    end
end
