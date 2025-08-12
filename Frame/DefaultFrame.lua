local addonName, addon = ...

addon.createDefaultFrame = function(titleText, width, height, isClosable, isResizable, maxWidth, maxHeight)
    if not titleText then
        error("Name and title are required for the default frame.")
    end
    
    if not tonumber(width) or not tonumber(height) then
        width, height = 800, 600
    end

    if not isClosable then
        isClosable = true
    end

    if not isResizable then
        isResizable = true
    end

    local frame = CreateFrame("Frame", addonName .. "MainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 32,
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    if isClosable then
        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function()
            frame:Hide()
        end)
    end
    
    if isResizable then
        if not tonumber(maxWidth) or not tonumber(maxHeight) then
            maxWidth, maxHeight = 1200, 800
        end

        frame:SetResizable(true)
        frame:SetResizeBounds(width, height, maxWidth, maxHeight)

        local resizeButton = CreateFrame("Button", nil, frame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

        resizeButton:EnableMouse(true)
        resizeButton:RegisterForDrag("LeftButton")
        resizeButton:SetScript("OnDragStart", function() frame:StartSizing("BOTTOMRIGHT") end)
        resizeButton:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", frame, "TOP", 0, -15)
        title:SetText(titleText)
    end
    
    return frame
end
