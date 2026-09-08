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

---Start of the current weekly-reset week, as a time() timestamp. Computed as
---the next reset (via the Blizzard API that also drives quest/vault reset
---countdowns) minus 7 days, so it works regardless of region/reset weekday.
---@return number timestamp
function addon.getCurrentWeekStartTime()
    return time() + C_DateAndTime.GetSecondsUntilWeeklyReset() - 7 * 24 * 60 * 60
end

---Converts a run's completionDate table ({year, month, monthDay, hour,
---minute, weekday}, as returned by C_MythicPlus.GetRunHistory) to a time()
---timestamp, for comparison against addon.getCurrentWeekStartTime().
---@param completionDate table|nil
---@return number|nil timestamp nil if completionDate is missing/malformed
function addon.completionDateToTimestamp(completionDate)
    if type(completionDate) ~= "table" then return nil end
    return time({
        year  = completionDate.year,
        month = completionDate.month,
        day   = completionDate.monthDay,
        hour  = completionDate.hour or 0,
        min   = completionDate.minute or 0,
        sec   = 0,
    })
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
