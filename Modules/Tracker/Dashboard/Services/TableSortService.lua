local addonName, addon = ...

addon.TableSortService = addon.TableSortService or {}

-- The only service in this addon with instances rather than a single shared
-- table: the Overview and Keystones tables each keep their own sort column and
-- direction, and a shared singleton would silently couple them — sorting one
-- table would reorder the other. One instance per table.
local instanceMethods = {}

---@param options table { defaultDirections, headerLocaleKeys, initialColumn }
---@return table sortState
function addon.TableSortService:new(options)
    return setmetatable({
        -- nil means "no explicit sort yet", which each table interprets itself:
        -- Overview starts on the dungeon name, Keystones keeps provider order.
        sortColumn        = options.initialColumn,
        sortDirection     = "asc",
        headerCells       = {},
        defaultDirections = options.defaultDirections,
        headerLocaleKeys  = options.headerLocaleKeys,
    }, { __index = instanceMethods })
end

---@return string|nil columnKey
function instanceMethods:getColumn()
    return self.sortColumn
end

---@return boolean
function instanceMethods:isAscending()
    return self.sortDirection == "asc"
end

---Header FontStrings are recreated on every render, so the previous ones must
---be dropped before the new ones register — otherwise updateIndicators() would
---write into orphaned frames.
function instanceMethods:forgetHeaderCells()
    wipe(self.headerCells)
end

---@param columnKey string
---@param fontString FontString
function instanceMethods:registerHeaderCell(columnKey, fontString)
    self.headerCells[columnKey] = fontString
end

---Repaints every registered header label with its localized text plus the
---"^"/"v" indicator on whichever column is currently sorted.
function instanceMethods:updateIndicators()
    local r, g, b = addon.colorToRGB("ARTIFACT")

    for columnKey, fontString in pairs(self.headerCells) do
        local localeKey = self.headerLocaleKeys[columnKey]
        local label     = addon.locale[localeKey] or localeKey
        local indicator = (columnKey == self.sortColumn) and (self:isAscending() and " ^" or " v") or ""
        fontString:SetText(label .. indicator)
        fontString:SetTextColor(r, g, b, 1)
    end
end

---Clicking the active column flips its direction; clicking another switches to
---it at that column's configured default direction.
---@param columnKey string
function instanceMethods:toggleColumn(columnKey)
    if self.sortColumn == columnKey then
        self.sortDirection = self.sortDirection == "asc" and "desc" or "asc"
    else
        self.sortColumn = columnKey
        self.sortDirection = self.defaultDirections[columnKey] or "asc"
    end

    self:updateIndicators()
end
