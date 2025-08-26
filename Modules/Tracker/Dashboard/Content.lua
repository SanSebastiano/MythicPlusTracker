local addonName, addon = ...

local function loadDungeonInfo()
    local dungeons = C_ChallengeMode.GetMapTable()
    local yOffset = 0
    local itemsPerRow = 2
    local itemWidth = (scrollFrame:GetWidth() - 100) / itemsPerRow
    local itemHeight = 80

    for i, mapID in ipairs(dungeons) do
        local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(mapID)

        if name then
            local column = (i - 1) % itemsPerRow
            local row = math.floor((i - 1) / itemsPerRow)

            -- Container for each dungeon item
            local dungeonFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
            dungeonFrame:SetSize(itemWidth, itemHeight)
            dungeonFrame:SetPoint("TOPLEFT", content, "TOPLEFT", column * (itemWidth + 0), -row * (itemHeight + 0))

            --dungeonFrame:SetBackdrop({
            --    bgFile= "Interface\\framegeneral\\uiframethewarwithin\\ui-frame-thewarwithin-cardparchmentwider",
            --    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            --    edgeSize = 16,
            --    insets = { left = 1, right = 1, top = 1, bottom = 1 }
            --})

            -- Background texture
            local bg = dungeonFrame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(dungeonFrame)
            bg:SetAtlas("UI-Frame-TheWarWithin-CardParchmentWider", true)

            -- Dungeon Icon
            local icon = dungeonFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("LEFT", dungeonFrame, "LEFT", 8, 8)
            icon:SetTexture(texture)

            -- Dungeon Name
            local nameText = dungeonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
            nameText:SetText(name)
            nameText:SetWidth(itemWidth - 48) -- Platz für Icon und Abstand
            nameText:SetJustifyH("LEFT")

            -- Time Limit
            local timeText = dungeonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            timeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
            timeText:SetText("Zeit: " .. math.floor(timeLimit / 60) .. " Min")
            timeText:SetWidth(itemWidth - 48)
            timeText:SetJustifyH("LEFT")

            -- Tabellen-Header
            local headerFrame = CreateFrame("Frame", nil, dungeonFrame)
            headerFrame:SetSize(itemWidth - 16, 15)
            headerFrame:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -2)

            -- Header-Hintergrund
            local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
            headerBg:SetAllPoints(headerFrame)
            if addon.isDebugMode then
                headerBg:SetColorTexture(0.6, 1.0, 0.6)
            else
                headerBg:SetColorTexture(0, 0, 0, 0.3)
            end

            -- Column Width
            local colWidth = (itemWidth - 16) / 4

            -- Header-Text
            local headers = {"Best", "Weekly", "Runs", "Success"}
            for j, headerText in ipairs(headers) do
                local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                header:SetPoint("LEFT", headerFrame, "LEFT", (j-1) * colWidth + 2, 0)
                header:SetSize(colWidth - 4, 15)
                header:SetText(headerText)
                header:SetJustifyH("CENTER")
            end

            -- Data-Frame
            local dataFrame = CreateFrame("Frame", nil, dungeonFrame)
            dataFrame:SetSize(itemWidth - 16, 15)
            dataFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -1)

            -- Data-Background
            local dataBg = dataFrame:CreateTexture(nil, "BACKGROUND")
            dataBg:SetAllPoints(dataFrame)
            if addon.isDebugMode then
                dataBg:SetColorTexture(1.0, 0.6, 0.6)
            else
                dataBg:SetColorTexture(0, 0, 0, 0.2)
            end

            -- Data-Text
            local dataValues = {"0", "0", "0", "0"}
            for j, dataText in ipairs(dataValues) do
                local data = dataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                data:SetPoint("LEFT", dataFrame, "LEFT", (j-1) * colWidth + 2, 0)
                data:SetSize(colWidth - 4, 15)
                data:SetText(dataText)
                data:SetJustifyH("CENTER")
            end
        end
    end

    -- Calculate the total height
    local totalRows = math.ceil(#dungeons / itemsPerRow)
    content:SetHeight(totalRows * (itemHeight + 10))
end
