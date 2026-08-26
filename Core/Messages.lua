local addonName, addon = ...

---@param text string
---@param chatType string|nil defaults to "SYSTEM"
local function sendMessage(text, chatType)
    chatType = chatType or "SYSTEM"
    if chatType == "SYSTEM" then
        print(text)
    else
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

---@param text string
---@param color string|nil e.g. "|cFFFF0000"
---@return string
local function coloredMessage(text, color)
    if not color or not text then
        return text or ""
    end
    return color .. text .. addon.colors.RESET
end

---@param text string
---@param color string|nil
---@param chatType string|nil defaults to "SYSTEM"
addon.chatMessage = function(text, color, chatType)
    local message = color and coloredMessage(text, color) or text
    sendMessage(message, chatType)
end

---@param text string
---@param color string|nil
---@param chatType string|nil defaults to "SYSTEM"
addon.addonMessage = function(text, color, chatType)
    local prefix = coloredMessage("[ " .. (C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName) .. " ]", addon.colors.GOLD)
    local message = color and coloredMessage(text, color) or text
    sendMessage(prefix .. " " .. message, chatType)
end

---@param text string
addon.errorMessage = function(text)
    addon.addonMessage(text, addon.colors.ERROR)
end

---@param text string
addon.successMessage = function(text)
    addon.addonMessage(text, addon.colors.SUCCESS)
end

---@param text string
addon.warningMessage = function(text)
    addon.addonMessage(text, addon.colors.WARNING)
end

---@param text string
addon.infoMessage = function(text)
    addon.addonMessage(text, addon.colors.INFO)
end

