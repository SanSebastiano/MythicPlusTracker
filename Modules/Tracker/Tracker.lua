local addonName, addon = ...

MPT_Tracker = {}

-- Dashboard tab indices. The Sidebar mirrors whichever Dashboard tab is active,
-- so both modules resolve their content against these shared values.
MPT_Tracker.TABS = {
    OVERVIEW = 1,
    RUNS = 2,
    KEYSTONES = 3,
}
