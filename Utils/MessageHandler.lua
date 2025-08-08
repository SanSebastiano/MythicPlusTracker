local addonName, addon = ...

---Sends a message to the specified chat output
---@param text string The message text to send
---@param chatType string|nil The chat type ("SYSTEM" or other), defaults to "SYSTEM"
---@return void
local function sendMessage(text, chatType)
    chatType = chatType or "SYSTEM"
    if chatType == "SYSTEM" then
        print(text)
    else
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

---Creates a colored message string with reset code
---@param text string The text to colorize
---@param color string|nil The color code (e.g., "|cFFFF0000")
---@return string The colored text with reset code, or original text if no color
local function coloredMessage(text, color)
    if not color or not text then
        return text or ""
    end
    return color .. text .. addon.colors.RESET
end

---Sends a chat message with optional color formatting
---@param text string The message text to send
---@param color string|nil Optional color code for the message
---@param chatType string|nil The chat type, defaults to "SYSTEM"
---@return void
addon.chatMessage = function(text, color, chatType)
    local message = color and coloredMessage(text, color) or text
    sendMessage(message, chatType)
end

---Sends an addon-specific message with title prefix and optional color
---@param text string The message text to send
---@param color string|nil Optional color code for the message text
---@param chatType string|nil The chat type, defaults to "SYSTEM"
---@return void
addon.addonMessage = function(text, color, chatType)
    local prefix = coloredMessage("[ " .. (C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName) .. " ]", addon.colors.GOLD)
    local message = color and coloredMessage(text, color) or text
    sendMessage(prefix .. " " .. message, chatType)
end

---Sends an error message with red color and addon prefix
---@param text string The error message text
---@return void
addon.errorMessage = function(text)
    addon.addonMessage(text, addon.colors.ERROR)
end

---Sends a success message with green color and addon prefix
---@param text string The success message text
---@return void
addon.successMessage = function(text)
    addon.addonMessage(text, addon.colors.SUCCESS)
end

---Sends a warning message with yellow color and addon prefix
---@param text string The warning message text
---@return void
addon.warningMessage = function(text)
    addon.addonMessage(text, addon.colors.WARNING)
end

---Sends an info message with blue color and addon prefix
---@param text string The info message text
---@return void
addon.infoMessage = function(text)
    addon.addonMessage(text, addon.colors.INFO)
end

---Sends a debug message with white color and addon prefix, only if debug mode is enabled
---@param text string The debug message text
---@return void
addon.debugMessage = function(text)
    if addon.debugMode then
        addon.addonMessage("[DEBUG] " .. text, addon.colors.WHITE, 'SYSTEM')
    end
end
