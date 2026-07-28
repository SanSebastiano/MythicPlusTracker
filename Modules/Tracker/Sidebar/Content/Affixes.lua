local addonName, addon = ...

local ICON_SIZE  = 28
local ICON_GAP   = 8
local AFFIXES_GAP = 10   -- gap after the previous card (Score)

local function loadAffixes(sidebar, cursor)
    addon.debugMessage("Loading sidebar: affixes...")

    -- Advance the cursor unconditionally (even if there are no affixes to show)
    -- so the vertical space below is reserved exactly like before this refactor.
    local y = cursor:current() - AFFIXES_GAP
    cursor:advance(AFFIXES_GAP + ICON_SIZE)

    local affixes = C_MythicPlus.GetCurrentAffixes() or {}
    if #affixes == 0 then return end

    local n       = #affixes
    local totalW  = n * ICON_SIZE + (n - 1) * ICON_GAP
    local startX  = 23 + math.floor((254 - totalW) / 2)

    local container = CreateFrame("Frame", nil, sidebar)
    container:SetSize(totalW, ICON_SIZE)
    container:SetPoint("TOPLEFT", sidebar, "TOPLEFT", startX, y)

    for i, affixInfo in ipairs(affixes) do
        local name, description, icon = C_ChallengeMode.GetAffixInfo(affixInfo.id)
        local xOff = (i - 1) * (ICON_SIZE + ICON_GAP)

        local iconFrame = CreateFrame("Frame", nil, container)
        iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
        iconFrame:SetPoint("TOPLEFT", container, "TOPLEFT", xOff, 0)

        local tex = iconFrame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(iconFrame)
        if icon and icon ~= 0 then
            tex:SetTexture(icon)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            tex:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        end

        local btn = CreateFrame("Button", nil, iconFrame)
        btn:SetAllPoints(iconFrame)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if name then
                GameTooltip:AddLine(name, 1, 1, 1)
                if description and description ~= "" then
                    GameTooltip:AddLine(description, nil, nil, nil, true)
                end
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
end

MPT_Sidebar.getAffixes = loadAffixes