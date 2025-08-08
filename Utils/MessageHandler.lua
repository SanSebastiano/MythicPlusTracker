local addonName, addon = ...

addon.coloredMessage = function(text, color)
    if not color or not text then
        return text or ""
    end
    return color .. text .. addon.colors.RESET
end

addon.errorMessage = function(text)
    return addon.coloredMessage(text, addon.colors.ERROR)
end

addon.successMessage = function(text)
    return addon.coloredMessage(text, addon.colors.SUCCESS)
end

addon.warningMessage = function(text)
    return addon.coloredMessage(text, addon.colors.WARNING)
end

addon.infoMessage = function(text)
    return addon.coloredMessage(text, addon.colors.INFO)
end
