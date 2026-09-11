local addonName, addon = ...

MPT_Dashboard = {}

-- Geometry every content page has to agree with. These used to be copied into
-- each page with a "-- matches Frame.lua" comment standing in for a shared
-- constant; the pages now read them from here.
MPT_Dashboard.LAYOUT = {
    WIDTH             = 800,
    HEIGHT            = 550,
    CONTENT_INSET     = 20,  -- aligns with the divider bar's left/right caps
    NAV_BOTTOM_MARGIN = 8,
}

MythicPlusTrackerDB = MythicPlusTrackerDB or {}

local frame
local contentWrapper

local activeContent = nil

local function showContent(loader, ...)
    if activeContent then
        activeContent:Hide()
        activeContent = nil
    end

    local panel = CreateFrame("Frame", nil, contentWrapper)
    panel:SetAllPoints(contentWrapper)
    activeContent = panel

    loader(MPT_Dashboard, panel, ...)
end

local function create(mainFrame)
    if frame then return frame end

    frame = CreateFrame("Frame", nil, mainFrame)

    frame:SetSize(MPT_Dashboard.LAYOUT.WIDTH, MPT_Dashboard.LAYOUT.HEIGHT)
    frame:SetPoint("TOPRIGHT", mainFrame)

    -- Same helper as the Sidebar border (see Sidebar/Sidebar.lua); the
    -- larger panel needs a smaller scale factor to line up the edges.
    addon.createFramedWindow(frame, 0.5)

    local function getDefaultTabIndex()
        if MythicPlusTrackerDB.dashboardDefaultTabInGroup and IsInGroup() then
            return MPT_Tracker.TABS.KEYSTONES
        end
        return MPT_Tracker.TABS.OVERVIEW
    end

    local tabCallbacks = {
        [MPT_Tracker.TABS.OVERVIEW] = function()
            if not addon.Player:isMaxLevel() then return false end
            showContent(MPT_Dashboard.loadDungeons)
            MPT_Sidebar:showForTab(MPT_Tracker.TABS.OVERVIEW)
        end,
        [MPT_Tracker.TABS.RUNS] = function()
            if not addon.Player:isMaxLevel() then return false end
            showContent(MPT_Dashboard.loadRuns)
            MPT_Sidebar:showForTab(MPT_Tracker.TABS.RUNS)
        end,
        [MPT_Tracker.TABS.KEYSTONES] = function()
            if not addon.Player:isMaxLevel() then return false end
            showContent(MPT_Dashboard.loadKeystones)
            MPT_Sidebar:showForTab(MPT_Tracker.TABS.KEYSTONES)
        end,
    }

    MPT_Dashboard:createNavigation(frame, tabCallbacks)

    frame:SetScript("OnShow", function()
        if contentWrapper then contentWrapper:Hide() end
        activeContent = nil

        contentWrapper = CreateFrame("Frame", nil, frame)
        contentWrapper:SetAllPoints(frame)

        addon.debugMessage("Dashboard Frame OnShow")

        -- Ahead of the max-level guard below, so the icon is also correctly
        -- hidden on the not-max-level page.
        MPT_Dashboard:refreshBonusEventIcon()

        if not addon.Player:isMaxLevel() then
            MPT_Dashboard:setActiveNavTab(MPT_Tracker.TABS.OVERVIEW)
            MPT_Dashboard:loadNotMaxLevel(contentWrapper)
            return
        end

        local defaultTab = getDefaultTabIndex()
        MPT_Dashboard:setActiveNavTab(defaultTab)

        if defaultTab == MPT_Tracker.TABS.KEYSTONES then
            -- Landing on the Keystones tab while the dropdown still says Alts
            -- would defeat the setting's whole point, so the group view comes
            -- along. Set before the content is built: the table, the dropdown
            -- and the Sidebar all read the mode as they render.
            addon.KeystoneEntryService:setModeOverride(addon.KeystoneEntryService.MODES.GROUP)
            showContent(MPT_Dashboard.loadKeystones)
            MPT_Sidebar:showForTab(MPT_Tracker.TABS.KEYSTONES)
        else
            -- Every open re-decides, so dropping the override here is what keeps
            -- the forced group view from outliving the group itself.
            addon.KeystoneEntryService:setModeOverride(nil)
            showContent(MPT_Dashboard.loadDungeons)
            MPT_Sidebar:showForTab(MPT_Tracker.TABS.OVERVIEW)
        end
    end)

    return frame
end

function MPT_Dashboard:getFrame(mainFrame)
    return create(mainFrame)
end

---Re-renders the Keystones tab content in place (e.g. from its refresh
---button), without touching the nav highlight or the rest of the frame.
function MPT_Dashboard:refreshKeystonesView()
    showContent(MPT_Dashboard.loadKeystones)
end

---Re-renders the Overview tab content in place (e.g. from its "current week
---only" checkbox), without touching the nav highlight or the rest of the frame.
function MPT_Dashboard:refreshDungeonsView()
    showContent(MPT_Dashboard.loadDungeons)
end
